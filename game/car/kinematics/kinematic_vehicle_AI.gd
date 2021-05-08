extends "res://car/kinematics/kinematic_vehicle.gd"

# mostly copied from vehicle_AI.gd
# I wish Godot could inherit from two scripts at once
onready var brain = get_node("brain")


var target_array = PoolVector3Array() # those are global
var current = 0
var prev = 0
#export var target_angle = 0.2
export var top_speed = 15 #50 kph?

var rel_loc
var dot
var predict
var cte # cross track error

#var target
#var rel_target # for setting a set heading

#steering
var angle = 0
var limit
var steer # just to make it easier to watch in remote tree
# to avoid creating new variables every tick
var gas = false
var braking = false
#var joy = Vector2(0,0)

#flag telling us to come to a halt
var stop = false
var stuck = false
var flag

var compare_pos = Vector3(0,0,0)

var debug = false

# pathing
var path
var pt_locs_rel = [] # those are relative to parent, for debugging

var elapsed_secs = 0
var start_secs = 1
var done = false
var emitted = false
signal path_gotten

# context steering
export var num_rays = 16
export var look_side = 3.0
var look_ahead = 10.0
export var brake_distance = 5.0

var interest = []
var danger = []
var rays = [] # debugging
var chosen_dir = Vector3.ZERO
var forward_ray = null

# cops only
var bribed = false

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	get_parent().connect("found_path", self, "_on_path_found")
	
	target_array.resize(0)
	
	# context steering
	rays.resize(num_rays)
	interest.resize(num_rays)
	danger.resize(num_rays)
	add_rays()
	
	var source = get_global_transform().origin
	
	# need a dummy target for before we get path
	var forw_global = get_global_transform().xform(Vector3(0, 0, -4))
	var target = forw_global
	
	# the brain is a 3D node, so it takes Vec3
	brain.target = target
	
	#register_debugging_lines()
	
	set_process(true)
	set_physics_process(true)

# TODO: add more rays in front (32 look ok in front), less in rear where 16 is enough
func add_rays():
	var angle = 2 * PI / num_rays
	for i in num_rays:
		var r = RayCast.new()
		$ContextRays.add_child(r)
		if i == 0 or i == 1 or i == num_rays-1:
			r.cast_to = Vector3.FORWARD * look_ahead
		else:
			r.cast_to = Vector3.FORWARD * look_side
		r.rotation.y = -angle * i
		r.add_exception(self)
		r.enabled = true
		# debug
		rays[i] = (r.cast_to.normalized()*4).rotated(Vector3(0,1,0), r.rotation.y)
	forward_ray = $ContextRays.get_child(0)

# ---------------------------------------
# cop stuff
# player clicked ok on bribe prompt
func _on_ok_click():
	print("Clicked ok to bribe")
	# TODO: deduct money
	# stop chase
	brain.set_state(brain.STATE_DRIVING)
	bribed = true
	
func coplights_on(player):
	var material = get_node("coplight").get_mesh().surface_get_material(0)
	#material.set_feature(SpatialMaterial.FEATURE_EMISSION, true)
	material.set_albedo(Color(1,0,0))
	get_node("SpotLight2").set_visible(true)
	get_node("SpotLight3").set_visible(true)
	
	# minimap icon flashes
	var map = player.get_node("BODY/Viewport_root/Viewport/minimap")
	map.flash_cop_arrow()
	
func coplights_off(player):
	var material = get_node("coplight").get_mesh().surface_get_material(0)
	#material.set_feature(SpatialMaterial.FEATURE_EMISSION, false)
	material.set_albedo(Color(0.5, 0, 0))
	get_node("SpotLight2").set_visible(false)
	get_node("SpotLight3").set_visible(false)
	
	# stop minimap flashing
	var map = player.get_node("BODY/Viewport_root/Viewport/minimap")
	map.stop_cop_arrow()

func start_chase():
	var playr = get_tree().get_nodes_in_group("player")[0]
	var playr_loc = playr.get_node("BODY").get_global_transform().origin
	#print("Player loc: " + str(playr_loc))
	# if player close enough
	if playr_loc.distance_to(get_global_transform().origin) < 10:
		#print("Player within 10 m of cop")
		# ignore player that is keeping to speed limit
		var playr_speed = playr.get_node("BODY").speed
		if playr_speed < 15:
			return
			
		# bugfix
		if stop:
			stop = false
		brain.set_state(brain.STATE_CHASE)
		brain.target = playr_loc
		
		# turn lights on
		coplights_on(playr)
		
		# notify player
		var msg = playr.get_node("BODY").get_node("Messages")
		msg.set_text("CHASE STARTED!" + "\n" + "Bribe the cops with Y100?")
		msg.enable_ok(true)
		msg.show()
		# set up the OK button
		if not msg.get_node("OK_button").is_connected("pressed", self, "_on_ok_click"):
			print("Not connected")
			# disconnect all others just in case
			for d in msg.get_node("OK_button").get_signal_connection_list("pressed"):
				#print(d["target"])
				msg.get_node("OK_button").disconnect("pressed", d["target"], "_on_ok_click")
			msg.get_node("OK_button").connect("pressed", self, "_on_ok_click")


#- ----------------------------
# debugging
func register_debugging_lines():
	var player = get_tree().get_nodes_in_group("player")[0]
	var draw = player.get_node("BODY/root/DebugDraw3D")
	
	if draw != null:
		var pos = get_global_transform().origin
		var end = brain.target
		draw.add_line(self, pos, end, 3, Color(0,0,1)) # blue
		
		draw.add_vector(self, velocity, 1, 3, Color(1,1,0)) # yellow
		draw.add_vector(self, steer, 1, 3, Color(1,0,0)) # red
		draw.add_vector(self, brain.desired, 1, 3, Color(1,0,1)) # purple
		draw.add_vector(self, chosen_dir, 1, 3, Color(0,1,0)) # green
		
		#print("Registered target line")

# mostly draws debugging
func _process(delta):
	# delay until everything is set up
	elapsed_secs += delta
	
	if (elapsed_secs > start_secs):
		if not done:
			register_debugging_lines()
		done = true


		var player = get_tree().get_nodes_in_group("player")[0]
		var draw = player.get_node("BODY/root/DebugDraw3D")
		draw.update_line(self, 0, get_global_transform().origin, brain.target)
		draw.update_vector(0, velocity)
		draw.update_vector(1, steer)
		draw.update_vector(2, brain.desired)

		# cop spots player -> starts chase
		if get_parent().is_in_group("cop"):
			# if not chasing already
			if brain.get_state() != brain.STATE_CHASE and not self.bribed:
				start_chase()
			# we're already chasing
			else:
				if self.bribed:
					# lights off
					var playr = get_tree().get_nodes_in_group("player")[0]
					coplights_off(playr)
					# stop chase
					brain.set_state(brain.STATE_DRIVING)
				else:
					var playr = get_tree().get_nodes_in_group("player")[0]
					var playr_loc = playr.get_node("BODY").get_global_transform().origin
					# if player hasn't outran us
					if playr_loc.distance_to(get_global_transform().origin) < 60:
						brain.target = playr_loc
						#print(str(brain.target))
						if not get_node("SpotLight2").is_visible():
							coplights_on(playr)
					else:
						# stop chase
						brain.set_state(brain.STATE_DRIVING)
						
						print("[Cop] player escaped!")
						# notify player
						var msg = playr.get_node("BODY").get_node("Messages")
						msg.set_text("CHASE ENDED!" + "\n" + "You escaped the cops!")
						msg.enable_ok(false)
						msg.show()
						
						coplights_off(playr)

# ------------------------------------
func setup_path(data_path):
	target_array.resize(0) #= []
	pt_locs_rel.resize(0) #= []
	# clear debug cubes
	get_parent().clear_cubes()
	
	path = data_path[0]
	var left_lane = data_path[1]
	var flip = data_path[2]
	
	# fix
	if get_parent().is_in_group("race_AI"):
		self.path = path
	if get_parent().is_in_group("race_AI"):
#		emit_signal("path_gotten")
#		print("Emitted path_gotten signal")
		# call directly because the signal seems to have gone MIA somehow
		if get_parent().race:
			get_parent().race._on_path_gotten(self)
	
	# stuff to do after getting path
	#print("[AI] We have a path to follow")
	
	for index in range(path.size()):
		#if (index > 0): #because #0 is our own location when we start
		target_array.push_back(path[index])
		
		pt_locs_rel.push_back(get_parent().to_local(path[index]))
			
		#print(target_array.size() == pt_locs_rel.size())
		#print("Target array " + str(target_array[target_array.size()-1]) + "pt_locs:" + str(pt_locs_rel[pt_locs_rel.size()-1]))
	
	# debug
	for i in range(pt_locs_rel.size()):
		var pt_loc = pt_locs_rel[i]
		get_parent().debug_cube(pt_loc)
#		if i == 0:
#			get_parent().debug_cube(pt_loc)	
		#if pt_loc == get_parent().to_local(target_array[0]):
		#	get_parent().debug_cube(pt_loc)
	
	
	# because the loops above take some time, to be 1000% certain we have the correct targets once we get moving
	get_node("Timer").start()


func _on_path_found(path):
	#print("Path was found!")
	setup_path(path)

# see line 340 (above)
func _on_Timer_timeout():
	#print("Timed out timer")
	emitted = false
	# reset points
	current = 0
	prev = 0
		
	# pass target to brain
	#print("Current: " + str(current))
	brain.target = target_array[current]
	#print("Target: " + str(brain.target))
	
	# bugfix
	if stop:
		stop = false
		
	# are we on an intersection?
	if get_parent().intersection:
		# if more than one car around, we wait
		if get_parent().intersection.cars.size() > 1 and get_parent().intersection.cars.keys()[0] != get_parent():
			# hack fix
			emitted = true
			stop = true


# ------------------------------------
# translates steering behaviors output 
# into actual steering input
func make_steering():
	# reset input
	gas = false
	braking = false
	#joy = Vector2(0,0)
	
	rel_loc = get_global_transform().xform_inv(brain.target)
	# dummy out the y value
	rel_loc = Vector3(rel_loc.x, 0, rel_loc.z)
	
	#this one actually reacts to rotations unlike the one using basis.z or linear velocity.z
	var forward_global = get_global_transform().xform(Vector3(0, 0, -4))
	#B-A = from A to B
	forward_vec = forward_global-get_global_transform().origin
	var tg_dir = brain.target - get_global_transform().origin
	dot = forward_vec.dot(tg_dir)
	
	
	#debug_cube(to_local(brain.target))
	
	#dot = -transform.basis.z.dot(tg_dir)
	
	#2D angle to target (local coords)
	angle = atan2(rel_loc.x, rel_loc.z)
	#if debug: print(str(angle))

	# predict position
	predict = predict_loc(1)
	# cross track error = distance to normal on line
	var gl_norm = get_normal_point()
	#B-A = from A to B
	cte = (get_normal_point()-predict).length()

	# steering from boid
	steer = brain.steer[0] # 0 is steering, 1 is desired vel
	
	
	# magic number to make inputs smaller
	var clx = clamp(brain.steer[0].x/25, -1, 1)
	#if debug: print("Clamped x: " + str(clx))

	# needed for race position
#	if get_parent().is_in_group("race_AI"):
#		#print("Race AI")
#		#print("Path: " + str(self.path))
#		if self.path != null and self.path.size() > 0 and not self.finished:
#			# paranoia
#			if current < path.size()-1: 
#				var pos = get_global_transform().origin
#				position_on_line = position_line(prev, current, pos, self.path)
#				#print("Position on line: " + str(position_on_line))
	
	#stop if we're supposed to
	if (stop):
		stopping()
	else:	
		# handle gas/brake
		# https://gamedev.stackexchange.com/questions/149875/how-can-i-apply-steering-behaviors-to-a-car-controlled-with-turning-and-accelera?rq=1
		# if desired velocity (speed) is higher than current
		if brain.steer[1].length() > velocity.length():
			if (velocity.length() > 0 and brain.steer[1].dot(velocity) > 0) or velocity.length() == 0:
			#print("Should be stepping on gas")
		#if brain.steer[0].z > 0: # and speed <= 200:
			# if very high angle and slow speed, brake (assume we're turning in an intersection)
#			if abs(angle) > 1 and speed > 2 and speed < 40:
#				if not reverse:
#					braking = true
#				else:
#					gas = true
#			else:
				gas = true
			
				# brake for sharp turns if going at speed
				if abs(clx) > 0.45 and speed > 30:
					if debug: print("Braking")
					if not reverse:
						braking = true
					else:
						gas = true
				else:
					gas = true
	#				#print(get_name() + " gas")
			else:
				if speed > 0 and speed < 10:
					if not reverse:
						braking = true
					else:
						gas = true
		else:
			if speed > 0 and speed < 10:
				if not reverse:
					braking = true
				else:
					gas = true

	# we don't use the joy for gas/brake, so far
	#joy = Vector2(clx, 0)
		
	# unstick
	if stuck:
		gas = false
		braking = true
		
	#return [gas. braking, joy]

# kinematic input
func get_input():
	make_steering()
	# context steering
	set_interest()
	set_danger()
	choose_direction()
	
	#joy = steer_data[0]
	# joystick
	#if joy != Vector2(0,0) and abs(joy.x) > 0.1: # deadzone
	#	steer_target = joy.x*0.2 # 4 #23 degrees limit
	
	if not stop:
		# chosen_dir is normalized before use here
		var a = angle_dir(-transform.basis.z, chosen_dir, transform.basis.y)
		steer_target = a * deg2rad(steering_limit)
	else:
		steer_target = 0
	$tmpParent/Spatial_FL.rotation.y = steer_angle
	$tmpParent/Spatial_FR.rotation.y = steer_angle
	
	# Hit brakes if obstacle dead ahead
	if forward_ray.is_colliding():
		var d = transform.origin.distance_to(forward_ray.get_collider().transform.origin)
		if d < brake_distance:
			braking = true
	
	
	if gas:
		acceleration = -transform.basis.z * engine_power
	if braking:
		# brakes
		acceleration += -transform.basis.z * braking_power


func angle_dir(fwd, target, up):
	# Returns how far "target" vector is to the left (negative)
	# or right (positive) of "fwd" vector.
	var p = fwd.cross(target)
	var dir = p.dot(up)
	return dir

func after_move():
	# don't do the next if we're a cop chasing
	if brain.get_state() != brain.STATE_CHASE:
		# select the next target if close enough (roughly half car length)
		if is_close_to_target() and not stop:
			#if debug:
			#	print("[AI] We're close to target" + str(brain.target) + " rel loc: " + str(rel_loc))

			# no longer on intersection?
			if 'intersection' in get_parent() and get_parent().intersection != null:
				# 32 is the amount of points an arc adds (see AI_pathing.gd line 209)
				if target_array.size() < 32 and current == 0:
					#print(get_parent().get_name(), " went straight, no longer on intersection")
					get_parent().intersection.cars.erase(get_parent())
					#get_parent().intersection.cars.remove(get_parent().intersection.cars.find(get_parent()))
					
					# prompt next car in line to drive
					if get_parent().intersection.cars.size() > 0:
						get_parent().intersection.cars.keys()[0].get_node("BODY").stop = false
						get_parent().intersection.cars.keys()[0].get_node("BODY").emitted = false
					
					get_parent().intersection = null
				if target_array.size() > 33 and current == 32:
					#print(get_parent().get_name(), " no longer on intersection after arc")
					get_parent().intersection.cars.erase(get_parent())
					#get_parent().intersection.cars.remove(get_parent().intersection.cars.find(get_parent()))
					
					# prompt next car in line to drive
					if get_parent().intersection.cars.size() > 0:
						get_parent().intersection.cars.keys()[0].get_node("BODY").stop = false
						get_parent().intersection.cars.keys()[0].get_node("BODY").emitted = false
					
					get_parent().intersection = null
	
			##do we have a next point?
			if (target_array.size() > current+1):
				#if not debug: #dummy out for now
				prev = current
				current = current + 1
				#else:
				#	stop = true
				#	print("Stopping")
				# send to brain
				brain.target = target_array[current]
				#if debug:
				#	print("New target" + str(brain.target))
			else:
				#print("We're at the end")
				stop = true
			
	#if we passed the point, don't backtrack
	if get_parent().is_in_group("race_AI"):
		if (dot < 0 and not stop):
			#print("Passed the point")
			##do we have a next point?
			if (target_array.size() > current+1):
				prev = current
				current = current + 1
				# send to brain
				brain.target = target_array[current]
			else:
				#print("We're at the end")
				stop = true

# -----------------------
# based on Kidscancode's https://kidscancode.org/godot_recipes/ai/context_map/
func set_interest():
	# Go forward unless we have somewhere to steer
	var path_direction = -transform.basis.z
	
	# see line 313
	if steer != Vector3.ZERO:
		path_direction = brain.steer[1].normalized()
		#path_direction = steer.normalized()
		
	for i in num_rays:
		var d = -$ContextRays.get_child(i).global_transform.basis.z
		d = d.dot(path_direction)
		interest[i] = max(0, d)


func set_danger():
	for i in num_rays:
		var ray = $ContextRays.get_child(i)
		danger[i] = 1.0 if ray.is_colliding() else 0.0


func choose_direction():
	for i in num_rays:
		if danger[i] > 0.0:
			interest[i] = 0.0
	chosen_dir = Vector3.ZERO
	for i in num_rays:
		# this is GLOBAL!!!!
		chosen_dir += -$ContextRays.get_child(i).global_transform.basis.z * interest[i]
	chosen_dir = chosen_dir.normalized()


# -------------------------------------
# based on https://natureofcode.com/book/chapter-6-autonomous-agents/
func predict_loc(s):
	var loc_dr = Vector3(0, 0, -speed)
	var gl_tg = get_global_transform().xform(loc_dr)
	var pos = get_global_transform().xform_inv(gl_tg)
	
	# debug (this one paints the whole track)
	#var par_rel = get_parent().get_global_transform().xform_inv(gl_tg)
	#get_parent().debug_cube(par_rel, true)
	
	# is any existing? (see vehicle.gd line 370)
#	if has_node("Debug"):
#		get_node("Debug").set_translation(pos)
#	else:
#		debug_cube(pos, true)
	
	return gl_tg

func get_normal_point(tg_point=predict):
	# dummy
	if current >= target_array.size():
		return get_global_transform().origin # i.e. offset from normal point is 0
	
	# lane line
	# B-A = vector from A->B
	var line = target_array[current]-target_array[prev]
	line = line.normalized()
	var pred_line = tg_point-target_array[prev]
	# A cos theta = scalar projection, where theta is the angle between A & B aka dot product
	var norm_point = target_array[prev] + pred_line.project(line)
	return norm_point # global
	
#-------------------------------------------

# AI generic functions
func is_close_to_target():
	var ret = false
	#print("Dist: " + str(rel_loc.length()))
	# only traffic AI
	if get_parent().is_in_group("AI"):
		##do we have a next point? if not, start stopping a bit earlier
		if (target_array.size() > current+1) == false:
			#print("Final point")
			if rel_loc.length() < 5:
				ret = true

	# if angle is very sharp and we're not too far to the side... 
	if abs(angle) > 1.4:
		if rel_loc.length() < 5:
			ret = true
	else:
		if rel_loc.length() <=2:
			ret = true
	
	#if ret: print("Close to target!")		
	return ret
	
func stopping():
	#relax steering
	if (abs(steer_angle) > 0.00):
		pass
		#joy.x = 0
		#left = false
		#right = false
		
	if (speed > 0.1 and not reverse):
		braking = true
	if (speed > 0.1 and reverse):
		gas = true
	
	# TODO: put into own function	
	# are we stopped?
	if speed < 0.3 and stop:
		#print("Have stopped...")

		# only traffic AI looks for new intersection target
		if get_parent().is_in_group("AI") and not emitted:
			# unregister from previous road
			var road_cars = get_parent().road.AI_cars
			# debug
			#for c in road_cars:
			#	print(c.get_name())
			road_cars.remove(road_cars.find(get_parent()))
			#print("[AI] Traffic looks for new path...")
			# +3 because of helper nodes in map
			get_parent().look_for_path(get_parent().end_ind+3, get_parent().left, get_parent().last_ind-3)
			emitted = true
			#debug
			#debug = true
			
			return
		# race AI just wants to drive off the intersection
		if get_parent().is_in_group("race_AI") and not emitted:
			# axe the debug cubes
			get_parent().clear_cubes()
			emitted = true
			var forw_global = get_global_transform().xform(Vector3(0, 0, -4))
			target_array.append(forw_global)
			stop = false

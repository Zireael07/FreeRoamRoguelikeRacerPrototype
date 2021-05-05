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
var joy = Vector2(0,0)

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
var emitted = false
signal path_gotten


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	get_parent().connect("found_path", self, "_on_path_found")
	
	target_array.resize(0)
	
	var source = get_global_transform().origin
	
	# need a dummy target for before we get path
	var forw_global = get_global_transform().xform(Vector3(0, 0, -4))
	var target = forw_global
	
	# the brain is a 3D node, so it converts Vec3
	# it takes care of converting to local coords
	brain.target = target
	
	set_process(true)
	set_physics_process(true)

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
	joy = Vector2(0,0)
	
	rel_loc = get_global_transform().xform_inv(brain.target)
	# dummy out the y value
	rel_loc = Vector3(rel_loc.x, 0, rel_loc.z)
	
	#this one actually reacts to rotations unlike the one using basis.z or linear velocity.z
	var forward_global = get_global_transform().xform(Vector3(0, 0, -4))
	#B-A = from A to B
	forward_vec = forward_global-get_global_transform().origin
	var tg_dir = brain.target - get_global_transform().origin
	dot = forward_vec.dot(tg_dir)
	
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
	steer = brain.steer
	#if brain.steer != Vector2(0,0):
	#	print("Brain steer: " + str(brain.steer) + " div: " + str(brain.steer.x/25))
	
	# magic number to make inputs smaller
	var clx = clamp(brain.steer.x/25, -1, 1)
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
		if brain.steer.y > 0: # and speed <= 200:
			# if very high angle and slow speed, brake (assume we're turning in an intersection)
			if abs(angle) > 1 and speed > 2 and speed < 40:
				if not reverse:
					braking = true
				else:
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
				#print(get_name() + " gas")
		else:
			if speed > 0 and speed < 10:
				if not reverse:
					braking = true
				else:
					gas = true

	# we don't use the joy for gas/brake, so far
	joy = Vector2(clx, 0)
		
	# unstick
	if stuck:
		gas = false
		braking = true
		
	#return [gas. braking, joy]

# kinematic input
func get_input():
	make_steering()
	#joy = steer_data[0]
	
	# joystick
	if joy != Vector2(0,0) and abs(joy.x) > 0.1: # deadzone
		steer_target = joy.x*0.2 # 4 #23 degrees limit
	
	# chosen_dir is normalized before use here!
	#var a = angle_dir(-transform.basis.z, chosen_dir, transform.basis.y)
	#steer_angle = a * deg2rad(steering_limit)
	$tmpParent/Spatial_FL.rotation.y = steer_angle
	$tmpParent/Spatial_FR.rotation.y = steer_angle
	if gas:
		acceleration = -transform.basis.z * engine_power
	if braking:
		# brakes
		acceleration += -transform.basis.z * braking_power
	
	# Hit brakes if obstacle dead ahead
#	tail_lights.emission_enabled = false
#	if forward_ray.is_colliding():
#		var d = transform.origin.distance_to(forward_ray.get_collider().transform.origin)
#		if d < brake_distance:
#			acceleration += -transform.basis.z * braking# * (1 - d/brake_distance)
#			tail_lights.emission_enabled = true


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
# based on https://natureofcode.com/book/chapter-6-autonomous-agents/
func predict_loc(s):
	var loc_dr = Vector3(0, 0, -speed)
	var gl_tg = get_global_transform().xform(loc_dr)
	var pos = get_global_transform().xform_inv(gl_tg)
	
	# debug (this one paints the whole track)
	#var par_rel = get_parent().get_global_transform().xform_inv(gl_tg)
	#get_parent().debug_cube(par_rel, true)
	
	# is any existing? (see vehicle.gd line 370)
	if has_node("Debug"):
		get_node("Debug").set_translation(pos)
	else:
		debug_cube(pos, true)
	
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
		joy.x = 0
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
			var forw_global = get_global_transform().xform(Vector3(0, 0, 4))
			target_array.append(forw_global)
			stop = false
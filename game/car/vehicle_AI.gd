extends "vehicle.gd"

# class member variables go here, for example:
#export (Vector3Array) var target_array = null

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
var left = false
var right = false
var joy = Vector2(0,0)

#flag telling us to come to a halt
var stop = false
var stuck = false
var flag

var compare_pos = Vector3(0,0,0)

var debug = false

# pathing
#var navigation_node
var path
var pt_locs_rel = [] # those are relative to parent, for debugging

var elapsed_secs = 0
var start_secs = 1
var emitted = false
signal path_gotten

# for race AI only
var finished = false
# cops only
var bribed = false

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	get_parent().connect("found_path", self, "_on_path_found")
	
	target_array.resize(0)
	
	#navigation_node = get_node("/root/Navigation")
	
	var source = get_global_transform().origin
	
	# need a dummy target for before we get path
	var forw_global = get_global_transform().xform(Vector3(0, 0, 4))
	var target = forw_global
	
	# the brain is a 3D node, so it converts Vec3
	# it takes care of converting to local coords
	brain.target = target
	
	#target_array.resize(0)
	#target_array.push_back(target)
	
	set_process(true)
	set_physics_process(true)


# debugging
func debug_draw_lines():
	#points
	var pos = get_transform().origin #get_translation()
	var points = PoolVector3Array()
	points.push_back(get_translation())
	# from relative location
	var gl_tg = get_global_transform().xform(rel_loc)
	var par_rel = get_parent().get_global_transform().xform_inv(gl_tg)
	points.push_back(Vector3(par_rel.x, 1, par_rel.z))
	
	#var dist = rel_loc.distance_to(compare_pos)
	#var dist = rel_loc.length()
	
	#if doing nothing because close to target, yellow
	if is_close_to_target():
	#if (dist < 3):
		get_parent().draw.draw_line_color(points, 3, Color(1,1,0,1))
	#if braking, draw red line
	#if braking:
	#elif not is_enough_dist(rel_loc, compare_pos, speed):  #(round(rel_loc.distance_to(compare_pos)) < round(speed)):
	#	get_parent().draw.draw_line_color(points, 3, Color(1,0,0,1))
	
	# debug dot
	elif dot < 0:
		get_parent().draw.draw_line_color(points, 3, Color(0,1,0,1)) # green line means dot < 0
	else:
		get_parent().draw.draw_line_color(points, 3, Color(0,0,1,1))
		

func debug_draw_path(pt_locs):
	if pt_locs.size() > 0:
		get_parent().draw.draw_line_color(pt_locs, 6, Color(1,0,0,1))

# draw debugging
func draw_debugging():
	# debug
	if (get_parent().draw != null):
		debug_draw_lines()
		#debug_draw_path(pt_locs_rel)
		
	if (get_parent().draw_arc != null):
#			if angle > 0:
#				# the minus is there solely for display purposes
#				get_parent().draw_arc.draw_arc_poly(get_translation(), 90-get_rotation_degrees().y, -rad2deg(angle), Color(1,0,0))
#			else:
#				get_parent().draw_arc.draw_arc_poly(get_translation(), 90-get_rotation_degrees().y, -rad2deg(angle), Color(0,1,0))

		# draw desired steer
		#points
		var pos = get_transform().origin #get_translation()
		var points = PoolVector3Array()
		# this is the start point of most drawing
		points.push_back(get_translation())
		# 25 is a magic number (see line 412)
		# (steer > 0 is left, < 0 is right)
		var st = Vector3(brain.steer.x/25, 1, 4*clamp(brain.steer.y, -1, 1))
		#print("Disp steer: ", st)
		points.push_back(get_translation() + st)
		get_parent().draw_arc.draw_line_color(points, 3, Color(1,0,1))

		# draw velocity
#			# from relative location
#			var loc_to_dr = Vector3(brain.velocity.x, 1, brain.velocity.y)
#			var gl_tg = get_global_transform().xform(loc_to_dr)
#			var par_rel = get_parent().get_global_transform().xform_inv(gl_tg)
#			points.push_back(Vector3(par_rel.x, 1, par_rel.z))

#			get_parent().draw_arc.draw_line_color(points, 3, Color(1,0,1))

		# draw forward vector
		# from relative location
#		var loc_dr = Vector3(0, 0, 4)
#		var gl_tg = get_global_transform().xform(loc_dr)
#		var par_rel = get_parent().get_global_transform().xform_inv(gl_tg)
#		points.push_back(Vector3(par_rel.x, 1, par_rel.z))
#		get_parent().draw_arc.draw_line_color(points, 3, Color(1,0,1))

		# draw lane line
#		if pt_locs_rel.size() > 0 and current < pt_locs_rel.size():
#			var par_rel = pt_locs_rel[prev]
#			points.push_back(Vector3(par_rel.x, 1, par_rel.z))
#
#			par_rel = pt_locs_rel[current]
#			points.push_back(Vector3(par_rel.x, 1, par_rel.z))
#			get_parent().draw_arc.draw_line_color(points, 3, Color(0,1,0))

		# draw line from prev to us
#		if pt_locs_rel.size() > 0:
#			var par_rel = pt_locs_rel[prev]
#			points.push_back(Vector3(par_rel.x, 1, par_rel.z))
#			points.push_back(get_translation())
#			get_parent().draw_arc.draw_line_color(points, 3, Color(0,1,0))
			
		# draw line from us to normal point
#		if pt_locs_rel.size() > 0:
#			points.push_back(get_translation())
#			var gl_norm = get_normal_point()
#			var par_rel = get_parent().get_global_transform().xform_inv(gl_norm)
#			points.push_back(Vector3(par_rel.x, 1, par_rel.z))
#			get_parent().draw_arc.draw_line_color(points, 3, Color(0,1,0))

# ---------
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
	if playr_loc.distance_to(get_node("BODY").get_global_transform().origin) < 10:
		#print("Player within 10 m of cop")
		# ignore player that is keeping to speed limit
		var playr_speed = playr.get_node("BODY").get_linear_velocity().length()
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

# -------------------------------
# mostly draws debugging
func _process(delta):
	# delay until everything is set up
	elapsed_secs += delta
	
	if (elapsed_secs > start_secs):
		draw_debugging()
		
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
				else:
					var playr = get_tree().get_nodes_in_group("player")[0]
					var playr_loc = playr.get_node("BODY").get_global_transform().origin
					# if player hasn't outran us
					if playr_loc.distance_to(get_node("BODY").get_global_transform().origin) < 60:
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
			get_parent().race._on_path_gotten()
	
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

func _on_Timer_timeout():
	print("Timed out timer")
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

# translates steering behaviors output 
# into actual steering input (gas/brake/left/right)
func _physics_process(delta):
	
		# reset input
		gas = false
		braking = false
		left = false
		right = false
		joy = Vector2(0,0)

		rel_loc = get_global_transform().xform_inv(brain.target)
		# dummy out the y value
		rel_loc = Vector3(rel_loc.x, 0, rel_loc.z)

		# needs to be 3D, so fake it
		#rel_loc = Vector3(loc.x, 1, loc.brain.target.y)
		
		#this one actually reacts to rotations unlike the one using basis.z or linear velocity.z
		var forward_global = get_global_transform().xform(Vector3(0, 0, 4))
		#B-A = from A to B
		forward_vec = forward_global-get_global_transform().origin
		var tg_dir = brain.target - get_global_transform().origin
		dot = forward_vec.dot(tg_dir)
		
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
		if get_parent().is_in_group("race_AI"):
			#print("Race AI")
			#print("Path: " + str(self.path))
			if self.path != null and self.path.size() > 0 and not self.finished:
				# paranoia
				if current < path.size()-1: 
					var pos = get_global_transform().origin
					position_on_line = position_line(prev, current, pos, self.path)
					#print("Position on line: " + str(position_on_line))
		
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
		

#		if brain.steer.x < 0:
#			left = true
#		else:
#			right = true

		

		
		#if we're over the limit, relax steering
#		limit = get_steering_limit()
#		if (get_steering() > limit):
#			left = true
#		if (get_steering() < -limit):
#			right = true
		
		
		# we don't use the joy for gas/brake, so far
		joy = Vector2(clx, 0)
		
		# unstick
		if stuck:
			gas = false
			braking = true
		
		process_car_physics(delta, gas, braking, left, right, joy)
		
		# test stuck detection
		if gas and not reverse and speed < 1:
			#print("AI ", get_parent().get_name(), " STUCK!!!")
			if get_node("StuckTimer").get_time_left() == 0:
				get_node("StuckTimer").start()
				print("AI ",  get_parent().get_name(), " started timer ", get_node("StuckTimer").get_time_left())
			#else:
			#	print("Timer already running")
		elif gas and speed >= 1:
			#print("No longer stuck")
			# abort stuck timer
			get_node("StuckTimer").stop()
		
		
		# don't do the next if we're a cop chasing
		if brain.get_state() != brain.STATE_CHASE:
			# select the next target if close enough (roughly half car length)
			if is_close_to_target() and not stop:
				#if debug:
				#	print("[AI] We're close to target" + str(brain.target) + " rel loc: " + str(rel_loc))
	
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
	var loc_dr = Vector3(0, 0, speed)
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

func get_normal_point():
	# dummy
	if current >= target_array.size():
		return get_global_transform().origin # i.e. offset from normal point is 0
	
	# lane line
	# B-A = vector from A->B
	var line = target_array[current]-target_array[prev]
	line = line.normalized()
	var pred_line = predict-target_array[prev]
	# A cos theta = scalar projection, where theta is the angle between A & B aka dot product
	var norm_point = target_array[prev] + pred_line.project(line)
	return norm_point # global

# --------------------------
func _on_StuckTimer_timeout():
	print("AI ", get_parent().get_name(), " stuck, start reverse timer")
	stuck = true
	get_node("ReverseTimer").start()


func _on_ReverseTimer_timeout():
	print("AI ", get_parent().get_name(), " done reversing!")
	stuck = false


# ------------------------

#	func update(delta):
#		car.flag = ""
#
#		#data
#		car.speed = car.get_linear_velocity().length();
#		#var forward_vec = car.get_translation() + car.get_global_transform().basis.z
#		var forward_vec = car.get_global_transform().xform(Vector3(0, 0, 4))
#
#		car.rel_loc = car.get_global_transform().xform_inv(car.get_target(car.current))
#
#		#2D angle to target (local coords)
#		car.angle = atan2(car.rel_loc.x, car.rel_loc.z)
#
#		#is the target in front of us or not?
#		var pos = car.get_global_transform().origin
#		#B-A = from A to B
#		var target_vec = car.get_target(car.current) - pos
#		#print("[AI] target_vec " + str(target_vec))
#		car.dot = forward_vec.dot(target_vec)
#		#print("Dot: " + str(car.dot))
#
#		
#
#		#BEHAVIOR
#
#		#if we're over the limit, relax steering
#		car.limit = car.get_steering_limit()
#		if (car.get_steering() > car.limit):
#			car.left = true
#		if (car.get_steering() < -car.limit):
#			car.right = true
#
#

#			# detect collisions
#			car.collision_avoidance()
#
#
#			if not (car.flag.find("AVOID") != -1):
#				# go back on track if too far away from the drive line
#				car.go_back(pos)
#
#				if not car.flag == "GOING BACK":
#					#handle gas/brake
#					if car.is_enough_dist(car.rel_loc, car.compare_pos, car.speed):
#						if (car.speed < car.top_speed):
#							car.gas = true
#					else:
#						if (car.speed > 1):
#							car.braking = true
#
#					#if we're close to target, do nothing
#					if (car.rel_loc.distance_to(car.compare_pos) < 3) and abs(car.angle) < 0.9:
#						#fixed_angling()
#						#print("Close to target, don't deviate")
#						#relax steering
#						if (abs(car.get_steering()) > 0.02):
#							car.left = false
#							car.right = false
#
#					else:
#						#normal stuff
#						car.fixed_angling()
#
#		# predict wheel angle
#		car.predicted_steer = car.predict_steer(delta, car.left, car.right)




#class LaneChangeState:
#	var car
#	var mark
#
#	var lane_change_tg
#	var lane_change_angle = -0.2
#	var or_target 
#	var initial_pos
#	var delta_change = null
#	var mx_speed = 10 #200
#	var done = false
#
#	# how it works - head (angle) to right lane, then -(angle) again to straighten up
#
#	func _init(car):
#		self.car = car
#
#		self.initial_pos = car.get_global_transform()
#		print("Starting lane change: " + str(self.initial_pos.origin))
#		print("Angle " + str(lane_change_angle) + " mx speed: " + str(mx_speed))
#
#
#		# set target = forced heading
#		var test_dist = car.get_test_dist_from_angle_speed(lane_change_angle, mx_speed)
#		print("Calculated test_dist " + str(test_dist))
#		car.rel_target = (Vector3(0, 0, 1)*test_dist).rotated(Vector3(0,1,0), lane_change_angle)
#		car.target = car.to_global(car.rel_target)
#		self.or_target = car.target
#		print("Target: " + str(car.target))
#
#
#	func update(delta):
#		# setup
#		car.flag = ""
#
#		# reset input
#		car.gas = false
#		car.braking = false
#		car.left = false
#		car.right = false
#
#		car.speed = car.get_linear_velocity().length();
#		var forward_vec = car.get_translation() + car.get_global_transform().basis.z
#
#		car.rel_loc = car.get_global_transform().xform_inv(car.target)
#
#		#2D angle to target (local coords)
#		car.angle = atan2(car.rel_loc.x, car.rel_loc.z)
#
#		#is the target in front of us or not?
#		var pos = car.get_transform().origin
#		#B-A = from A to B
#		var target_vec = car.target - pos
#		car.dot = forward_vec.dot(target_vec)
#
#
#		# obstacle avoidance
#		#car.collision_avoidance()
#
#		car.car_movement_lanes(mx_speed)
#
#		# predict wheel angle
#		car.predicted_steer = car.predict_steer(delta, car.left, car.right)
#
#		car.process_car_physics(delta, car.gas, car.braking, car.left, car.right)
#
#		# roughly half the car length
#		if (car.rel_loc.distance_to(Vector3(0,1.5,0)) < 2):
#			# usual behavior
#			# speedup
#			if self.or_target == car.target:
#				# pause
#				#Input.action_press("ui_cancel")
#
#				#car.emit_signal("changed_dir", car.get_transform().origin)
##				print("Location when turning back " + str(car.get_transform().origin))
##				delta_change = self.initial_pos.xform_inv(car.get_transform().origin)
#				#print("Delta pos: " + str(delta_change))
##				print("Speed when turning back: " + str(car.speed))
##				print("Angle when turning back: " + str(car.angle) + " " + str(rad2deg(car.angle)) + " deg")
#				var new_angle = -lane_change_angle
#				var test_dist = car.get_test_dist_from_angle_speed(new_angle, max(car.speed, mx_speed))
#				car.rel_target = (Vector3(0, 0, 1)*test_dist).rotated(Vector3(0,1,0), new_angle) # test angle
#				car.target = car.to_global(car.rel_target)
#			else:
#				#print("Location when maneuver finished " + str(car.get_transform().origin))
##				var comp = self.initial_pos.translated(delta_change)
#				#print("Delta pos: " + str(comp.xform_inv(car.get_transform().origin)))
#				car.stop = true
#				if not done:
#					car.emit_signal("lane_change_done", car.get_transform().origin)
#					done = true



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
	if (abs(get_steering()) > 0.00):
		left = false
		right = false
		
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
			print("[AI] Traffic looks for new path...")
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

# -----------------------------------------------
func go_back(pos):
	offset = offset_dist(get_target(prev), get_target(current), pos)
	if offset[0] > 3:
	#print("Trying to go back because too far off the path")
		flag = "GOING BACK"
		
		#rel_loc = get_global_transform().xform_inv(offset[1])
		#angle = atan2(rel_loc.x, rel_loc.z)
		var rel_target = get_global_transform().xform_inv(offset[1])
		var rel_angle = atan2(rel_target.x, rel_target.z)
		#print("Angle to new target: " + str(rel_angle))
		#print("Offset loc: 	" + str(rel_loc.x) + " " + str(rel_loc.z))
		if (not reverse and speed > 10):
			braking = true
		else:
			gas = true
		
		simple_steering(rel_angle)

	
func get_target(index):
	return target_array[index]
	
func get_next_target():
	return get_target(current+1)

func get_steering_limit():
	var limit
	var speed = get_linear_velocity().length()
	if (speed > 28): #100 kph
		limit = 0.1
	else:
		limit = 0.3
	
	return limit

func is_enough_dist(rel_loc, compare_pos, speed):
	#let's keep some speed
	var enough_dist = round(rel_loc.distance_to(compare_pos)) > round(speed)*1.6
	
	#come to a perfect stop if it's the last node
	if not target_array.size() > current+1:
		enough_dist = round(rel_loc.distance_to(compare_pos)) > round(speed)*2
	#else:
		#print("Approaching node")

	return enough_dist

func fixed_angling():
	# default limit
	if limit == null:
		limit = 0.3
	
	
	flag = "ANGLE TO TARGET"
	
	if angle > 0 and dot > 0: # disregard points behind us	
		if angle > predicted_steer:
			if (get_steering() > -limit):
				left = true
			else:
				left = false
				right = false
		else:
			left = false
			right = false
	elif angle < 0 and dot > 0:
		if angle < -predicted_steer:
			if (get_steering() < limit):
				right = true
			else:
				left = false
				right = false
		else:
				left = false
				right = false

# almost a copy of standard steer behavior (but we don't disregard points behind us)				
func simple_steering(rel_angle):
	if rel_angle > 0:
		if rel_angle > predicted_steer:
			if (get_steering() > -limit):
				left = true
			else:
				left = false
				right = false
		else:
			left = false
			right = false
	elif rel_angle < 0:
		if rel_angle < -predicted_steer:
			if (get_steering() < limit):
				right = true
			else:
				left = false
				right = false
		else:
				left = false
				right = false

# changing lanes
func get_test_dist_from_angle_speed(angle, speed):
	# 1.5 s is enough to reach 95-98% of target angle 
	# regardless of angle
	#overestimate a bit to account for " no steer at <3 rule" and "get next at <2"
	var ret = 1.5*speed + 4 
	#	print("Target dist from angle and speed: " + str(ret))
	return ret

func handle_gas_brake_lanes(mx_speed):
	if stop:
		stopping()
	else:
		# if angle to target is big, brake
		if abs(angle) > 0.9 and speed > 20 and not reverse: #radians
			braking = true
		else:			
			if speed < mx_speed:
				gas = true
			else:
				braking = true

				
func car_movement_lanes(mx_speed):
	if not (flag.find("AVOID") != -1):
		#print("Normal gas/brake handling")
		handle_gas_brake_lanes(mx_speed)
		#if we're close to target, do nothing
		if (rel_loc.distance_to(compare_pos) < 3) and dot > 0:
#			print("Close to target, don't deviate")
			#relax steering
			if abs(get_steering()) > 0.00:
				left = false
				right = false
			# normal
		else:
			#normal stuff
			fixed_angling()

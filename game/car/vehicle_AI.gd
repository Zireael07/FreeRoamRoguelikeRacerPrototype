extends "vehicle.gd"

# class member variables go here, for example:
#export (Vector3Array) var target_array = null
var target_array = PoolVector3Array()
var current = 0
var prev = 0
export var target_angle = 0.2
export var top_speed = 15 #50 kph?

var rel_loc
var dot

#steering
var angle
var limit
var gas = false
var braking = false
var left = false
var right = false

#flag telling us to come to a halt
var stop = false
var flag

var compare_pos = Vector3(0,0,0)

# pathing
var navigation_node
var path

var elapsed_secs = 0
var start_secs = 1

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	target_array.resize(0)
	
	navigation_node = get_node("/root/root")
	
	var source = get_global_transform().origin
	
	# need a dummy target for before we get navigation
	var forw_global = get_global_transform().xform(Vector3(0, 0, 4))
	var target = forw_global
	
	target_array.resize(0)
	target_array.push_back(target)
	
	set_process(true)
	set_physics_process(true)

func debug_draw_lines():
	#points
	var pos = get_transform().origin #get_translation()
	var points = PoolVector3Array()
	points.push_back(get_translation())
	# from relative location
	var gl_tg = get_global_transform().xform(rel_loc)
	var par_rel = get_parent().get_global_transform().xform_inv(gl_tg)
	points.push_back(Vector3(par_rel.x, 1, par_rel.z))
	
	#if doing nothing because close to target, yellow
	if (rel_loc.distance_to(compare_pos) < 3):
		get_parent().draw.draw_line_color(points, 3, Color(1,1,0,1))
	#if braking, draw red line
	elif not is_enough_dist(rel_loc, compare_pos, speed):  #(round(rel_loc.distance_to(compare_pos)) < round(speed)):
		get_parent().draw.draw_line_color(points, 3, Color(1,0,0,1))
	else:
		get_parent().draw.draw_line_color(points, 3, Color(0,0,1,1))

func _process(delta):
	# delay getting the path until everything is set up
	elapsed_secs += delta
	
	if (elapsed_secs > start_secs):
		if (path == null):
#			
			path = get_parent().find_path()
			#if path != null:
			#	print(get_parent().get_name() + " found path: " + String(path))
#			
			if (path != null and path.size() > 0):
#			print("We have a path to follow")
				for index in range(path.size()):
					if (index > 0): #because #0 is our own location
						target_array.push_back(path[index])


		# debug
		if (get_parent().draw != null):
			debug_draw_lines()

func _physics_process(delta):
	flag = ""
	
	#input
	gas = false
	braking = false
	left = false
	right = false

	#data
	speed = get_linear_velocity().length();
	var forward_vec = get_translation() + get_global_transform().basis.z
	
	rel_loc = get_global_transform().xform_inv(get_target(current))
	
	#2D angle to target (local coords)
	angle = atan2(rel_loc.x, rel_loc.z)
	
	#is the target in front of us or not?
	var pos = get_global_transform().origin
	#B-A = from A to B
	var target_vec = get_target(current) - pos
	dot = forward_vec.dot(target_vec)
	
	#BEHAVIOR
	
	#if we're over the limit, relax steering
	limit = get_steering_limit()
	if (get_steering() > limit):
		left = true
	if (get_steering() < -limit):
		right = true


	#stop if we're supposed to
	if (stop):
		stopping()
	else:
		# detect collisions
		collision_avoidance()
					
		
		if not (flag.find("AVOID") != -1):
			# go back on track if too far away from the drive line
			go_back(pos)
			
			if not flag == "GOING BACK":
				#handle gas/brake
				if is_enough_dist(rel_loc, compare_pos, speed):
					if (speed < top_speed):
						gas = true
				else:
					if (speed > 1):
						braking = true
		
				#if we're close to target, do nothing
				if (rel_loc.distance_to(compare_pos) < 3):
					#print("Close to target, don't deviate")
					#relax steering
					if (abs(get_steering()) > 0.02):
						left = false
						right = false
					
				else:
					#normal stuff
					fixed_angling()
	
	# predict wheel angle
	predicted_steer = predict_steer(delta, left, right)
	
	process_car_physics(delta, gas, braking, left, right)
	
	#if we passed the point, don't backtrack
	if (dot < 0 and not stop):
		##do we have a next point?
		if (target_array.size() > current+1):
			prev = current
			current = current + 1
		else:
			#print("We're at the end")
			stop = true
	
	
	if (rel_loc.distance_to(Vector3(0,1.5,0)) < 2):
		#print("We're close to target")
		
		##do we have a next point?
		if (target_array.size() > current+1):
			prev = current
			current = current + 1
		else:
			#print("We're at the end")
			stop = true

# AI	
	
func stopping():
	#relax steering
	if (abs(get_steering()) > 0.00):
		left = false
		right = false
		
	if (speed > 0.2 and not reverse):
		braking = true
	if (speed > 0.2 and reverse):
		gas = true

func collision_avoidance():
	if has_node("RayFront") and get_node("RayFront").get_collider_hit() != null:
		# if all rays hit
		if has_node("RayRightFront") and has_node("RayLeftFront") \
		and get_node("RayRightFront").get_collider_hit() != null and get_node("RayLeftFront").get_collider_hit() != null:
			#print(get_parent().get_name() + " all three rays hit")
			flag = "AVOID - REVERSE"
			braking = true
			# pick direction to go to
			if get_parent().left:
				left = true
			else:
				right = true

		else:
		
			# if one of the other rays collides
			if has_node("RayRightFront") and get_node("RayRightFront").get_collider_hit() != null:
				right = true
				flag = "AVOID - REVERSE"
				braking = true
			elif has_node("RayLeftFront") and get_node("RayLeftFront").get_collider_hit() != null:
				left = true
				flag = "AVOID - REVERSE"
				braking = true
			else:
				if (not reverse and speed > 10):
					flag = "AVOID - BRAKE"
					braking = true
				else:
					flag = "AVOID"
					gas = true
	
	elif has_node("RayRightFront") and get_node("RayRightFront").is_colliding() and (get_node("RayRightFront").get_collider() != null):
			#print("Detected obstacle " + (get_node("RayRightFront").get_collider().get_parent().get_name()))
			if has_node("RayLeftFront"):
				if not (get_node("RayLeftFront").is_colliding() and (get_node("RayLeftFront").get_collider() != null)):
					#print(get_parent().get_name() + " rays cancelling out")
				#else:
					flag = "AVOID - LEFT TURN"
					left = true
			
			if (not reverse and speed > 10):	
				#flag = "AVOID"
				braking = true
			else:
				gas = true
			
	elif has_node("RayLeftFront"):
		if get_node("RayLeftFront").is_colliding() and (get_node("RayLeftFront").get_collider() != null):
			#print(get_parent().get_name() + " detected left obstacle " + (get_node("RayLeftFront").get_collider().get_parent().get_name()))
			flag = "AVOID - RIGHT TURN"
			right = true
			
			if (not reverse and speed > 10):
				#flag = "AVOID"
				braking = true
			else:
				gas = true

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
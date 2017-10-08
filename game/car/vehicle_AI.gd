extends "vehicle.gd"

# class member variables go here, for example:
#export (Vector3Array) var target_array = null
var target_array = Vector3Array()
var current = 0
export var target_angle = 0.2
export var top_speed = 15 #50 kph?

var rel_loc
var dot

#steering
var angle
var gas = false
var brake = false
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
	set_fixed_process(true)

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

func _fixed_process(delta):
	flag = ""
	
	#input
	gas = false
	brake = false
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
	var limit = get_steering_limit()
	if (get_steering() > limit):
		left = true
	if (get_steering() < -limit):
		right = true


	#stop if we're supposed to
	if (stop):
		stopping()
	else:
		# detect collisions
		if has_node("RayFront"):
			if get_node("RayFront").get_collider_hit() != null:
				if has_node("RayRightFront") and has_node("RayLeftFront"):
					if get_node("RayRightFront").get_collider_hit() != null:
						if get_node("RayLeftFront").get_collider_hit() != null:
							print(get_parent().get_name() + " all three rays hit")
							flag = "AVOID"
							brake = true
				
				
				if (not reverse and speed > 4):
					flag = "AVOID"
					brake = true
		
		if has_node("RayRightFront"):
			if get_node("RayRightFront").get_collider_hit() != null:
				#print("Detected obstacle " + (get_node("RayRightFront").get_collider().get_parent().get_name()))
				if has_node("RayLeftFront"):
					if get_node("RayLeftFront").get_collider_hit() != null:
						print(get_parent().get_name() + " rays cancelling out")
					else:
						flag = "AVOID"
						left = true
				
				if (not reverse and speed > 4):
					flag = "AVOID"
					brake = true
		
		if has_node("RayLeftFront"):
			if get_node("RayLeftFront").get_collider_hit() != null:
				#print("Detected obstacle " + (get_node("RayLeftFront").get_collider().get_parent().get_name()))
				flag = "AVOID"
				right = true
				
				if (not reverse and speed > 4):
					brake = true	
	
		if not flag == "AVOID":
			#handle gas/brake
			if is_enough_dist(rel_loc, compare_pos, speed):
				if (speed < top_speed):
					gas = true
			else:
				if (speed > 1):
					brake = true
	
			#if we're close to target, do nothing
			if (rel_loc.distance_to(compare_pos) < 3):
				#print("Close to target, don't deviate")
				#relax steering
				if (abs(get_steering()) > 0.02):
					left = false
					right = false
				
			else:
				#normal stuff
				if (abs(angle) > target_angle):
					if (angle > 0):
						#Make AI cautious with steering
						if (get_steering() > -limit):
							left = true
					else:
						if (get_steering() < limit):
							right = true
				else:
					#print("The angle is less than target")
					#relax steering
	#				relax_steering(0.02)
					if (abs(get_steering()) > 0.02):
						left = false
						right = false
	
	process_car_physics(delta, gas, brake, left, right)
	
	#if we passed the point, don't backtrack
	if (dot < 0 and not stop):
		##do we have a next point?
		if (target_array.size() > current+1):
			current = current + 1
		else:
			#print("We're at the end")
			stop = true
	
	
	if (rel_loc.distance_to(Vector3(0,1.5,0)) < 2):
		#print("We're close to target")
		
		##do we have a next point?
		if (target_array.size() > current+1):
			current = current + 1
		else:
			#print("We're at the end")
			stop = true
	
	
func stopping():
	#relax steering
	if (abs(get_steering()) > 0.00):
		left = false
		right = false
		
	if (speed > 0.2 and not reverse):
		brake = true
	if (speed > 0.2 and reverse):
		gas = true
	
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

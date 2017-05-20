extends "vehicle.gd"

# class member variables go here, for example:
export (Vector3Array) var target_array = null
var current = 0
export var target_angle = 0.2
export var top_speed = 15 #50 kph?

#steering
var angle
var gas = false
var brake = false
var left = false
var right = false

#flag telling us to come to a halt
var stop = false

var compare_pos = Vector3(0,1.5,0)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_fixed_process(true)
	
func _fixed_process(delta):
	#input
	gas = false
	brake = false
	left = false
	right = false

	speed = get_linear_velocity().length();

	var rel_loc = get_global_transform().xform_inv(get_target(current))
	
	#2D angle to target (local coords)
	angle = atan2(rel_loc.x, rel_loc.z)
	
	#if we're over the limit, relax steering
	var limit = get_steering_limit()
	if (get_steering() > limit):
		left = true
	if (get_steering() < -limit):
		right = true
	#else:
	#stop if we're supposed to
	if (stop):
		stopping()	
	else:
		#handle gas/brake
		if (rel_loc.distance_to(compare_pos) > round(speed)):
		#if (rel_loc.distance_to(compare_pos) > 5):
			if (speed < top_speed):
				gas = true
		else:
			if (rel_loc.distance_to(compare_pos) > 5):
				brake = true

		#if we're close to target, do nothing
		if (rel_loc.distance_to(compare_pos) < 3):
			#print("Close to target, don't deviate")
			#relax steering
			if (abs(get_steering()) > 0.02):
				if (get_steering() > 0):
					left = true
				else:
					right = true
			
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
					if (get_steering() > 0):
						left = true
					else:
						right = true
	
	process_car_physics(gas, brake, left, right)
	
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
		if (get_steering() > 0):
			left = true
		else:
			right = true

	if (speed > 0 and not reverse):
		brake = true
	if (speed > 0 and reverse):
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

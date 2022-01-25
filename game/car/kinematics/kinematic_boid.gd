# steering behavior for kinematics
# this one returns global steering
extends Node3D

# Declare member variables here. Examples:
var velocity = Vector3.ZERO
var steer = [Vector3.ZERO, Vector3.ZERO]
var desired = Vector3.ZERO

var dist = 0.0


var max_speed = 30
var max_force = 15

var target = Vector3.ZERO


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# helper
func v3_clamp(vector, length):
	return vector.normalized() * length

# ------------------------------------------
# steering behaviors
func seek(target):
	var steering = Vector3.ZERO
	
	desired = target-get_global_transform().origin	
	dist = desired.length()
#	print("des: " + str(desired))
	desired = desired.normalized() * max_speed
	
	steering = v3_clamp((desired - velocity), max_force)
	return [steering, desired]

func arrive(target, slowing_radius):
	var steering = Vector3.ZERO
	
	desired = target-get_global_transform().origin
	dist = desired.length()
	#print("Dist: " + str(dist))
	
	if dist < slowing_radius:
#		print("Slowing... " + str(dist/slowing_radius))
		# inside slowing area
		desired = desired.normalized() * max_speed * (dist / slowing_radius)
	else:
		#print("Not slowing")
		# outside
		desired = desired.normalized() * max_speed

	# desired minus current vel
	steering = v3_clamp((desired-velocity), max_force)
	return [steering, desired]

# for holding speed
func match_velocity_length(target_spd, reverse=false):
	var steering = Vector3.ZERO
	var change = target_spd - velocity.length()
	
	var vel_for_des = Vector3.ZERO
	if target_spd > 0 and velocity.length() == 0: #< 0.01:
		#print("Pretend")
		# pretend it's bigger
		vel_for_des = Vector3.ONE
	else:
		vel_for_des = velocity
	
	desired = vel_for_des.normalized() * target_spd
	
	steering = v3_clamp((desired-velocity), max_force)
	
	return [steering, desired]
	

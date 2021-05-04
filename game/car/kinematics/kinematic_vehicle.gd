# http://kidscancode.org/godot_recipes/3d/kinematic_car/car_base/
extends KinematicBody

export var gravity = -20.0
export var wheel_base = 0.6
export var steering_limit = 10.0
export var engine_power = 6.0
export var braking = -9.0
export var friction = -2.0
export var drag = -2.0
export var max_speed_reverse = 3.0

var acceleration = Vector3.ZERO
var velocity = Vector3.ZERO
var steer_angle = 0.0

var steer_target = 0.0

# based on torcs
var SPEED_SENS = 0.7 # speed sensitivity factor
var STEER_SENS = 0.8
var SPEED_FACT = 1.0 #10.0
var FUDGE = 8 # account for TORCS timestep being 0.002 seconds (500Hz) and our physics tick is 60 hz


#speed
var speed = 0
var speed_int = 0
var speed_kph = 0

#lights
var headlight_one
var headlight_two
var taillights
var tail_mat

func _ready():
	#get lights
	headlight_one = get_node("SpotLight")
	headlight_two = get_node("SpotLight1")
	taillights = get_node("taillights")

func _physics_process(delta):
	
	# gives false negatives
	#if is_on_floor():
	get_input()
	apply_friction(delta)
	calculate_steering(delta)
	
	#acceleration.y = 0
	acceleration.y = gravity
	velocity += acceleration * delta
	
	# Set our velocity to a new variable (hvel) and remove the Y velocity.
	var hvel = velocity
	hvel.y = 0
	
	
	velocity = move_and_slide_with_snap(hvel, #velocity,
				-transform.basis.y, Vector3.UP, true)
				
	speed = velocity.length()

func apply_friction(delta):
	if velocity.length() < 0.2 and acceleration.length() == 0:
		velocity.x = 0
		velocity.z = 0
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + friction_force

func get_steering_angle(steer_target, delta):
	#steering
	if (steer_target < steer_angle):
		# original
		#var steer_change = STEER_SPEED*delta

		# TORCS style
		var press = 2 * 1 - 1
		var steer_change = press * STEER_SENS * delta  / (1.0 + SPEED_SENS * velocity.length() / SPEED_FACT) * FUDGE
#		var steer_change = press * STEER_SENS * delta / (1.0 + SPEED_SENS * get_linear_velocity().length() / SPEED_FACT)

		steer_angle -= steer_change
		if (steer_target > steer_angle):
			steer_angle = steer_target
	elif (steer_target > steer_angle):
		# original
		#var steer_change = STEER_SPEED*delta
		
		# TORCS style
		var press = 2 * 1 - 1
		var steer_change = press * STEER_SENS * delta  / (1.0 + SPEED_SENS * velocity.length() / SPEED_FACT) * FUDGE
#		var steer_change = press * STEER_SENS * delta / (1.0 + SPEED_SENS * get_linear_velocity().length() / SPEED_FACT)


		steer_angle += steer_change

		if (steer_target < steer_angle):
			steer_angle = steer_target

	return steer_angle

func calculate_steering(delta):
	steer_angle = get_steering_angle(steer_target, delta)
	
	var rear_wheel = transform.origin + transform.basis.z * wheel_base / 2.0
	var front_wheel = transform.origin - transform.basis.z * wheel_base / 2.0
	rear_wheel += velocity * delta
	#order of operation: forward by velocity and then rotate
	front_wheel += velocity.rotated(transform.basis.y, steer_angle) * delta
	var new_heading = rear_wheel.direction_to(front_wheel)

	var d = new_heading.dot(velocity.normalized())
	# going forward or reverse?
	if d > 0:
		velocity = new_heading * velocity.length()
	if d < 0:
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
	
	# this uses global parameters	
	look_at(global_transform.origin + new_heading, transform.basis.y)

func get_input():
	# Override this in inherited scripts for controls
	pass

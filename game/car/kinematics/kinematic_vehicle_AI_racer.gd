extends "kinematic_vehicle_AI.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# this is the global version, since the racers can be parented to something rotated
func calculate_steering(delta):
	steer_angle = get_steering_angle(steer_target, delta)
	
	# Using bicycle model (one front/rear wheel)
	var rear_wheel = global_transform.origin + global_transform.basis.z * wheel_base / 2.0
	var front_wheel = global_transform.origin - global_transform.basis.z * wheel_base / 2.0
	rear_wheel += velocity * delta

	#order of operation: forward by velocity and then rotate
	# for some reason global basis is not necessarily normalized
	# FIXME: possible slowdown?
	front_wheel += velocity.rotated(global_transform.basis.y.normalized(), steer_angle) * delta
	var new_heading = rear_wheel.direction_to(front_wheel)

	var d = new_heading.dot(velocity.normalized())
	# going forward or reverse?
	if d > 0:
		velocity = new_heading * velocity.length()
	if d < 0:
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
	
	# Point in the steering direction.
	# this uses global parameters	
	look_at(global_transform.origin + new_heading, Vector3.UP)


# kinematic input
func get_input():
	make_steering()
	
	chosen_dir = steer.normalized()
	
	# quick and easy, no need to compare relative positions/use joy input
	if not stop:
		# chosen_dir is normalized before use here
		var a = angle_dir(-global_transform.basis.z, chosen_dir, transform.basis.y)
		if reverse:
			a = -a # flip the sign
		steer_target = a * deg2rad(steering_limit)
	else:
		steer_target = 0
	$tmpParent/Spatial_FL.rotation.y = steer_angle
	$tmpParent/Spatial_FR.rotation.y = steer_angle

	if gas:
		# make it easier to get going
		if velocity.length() < 1:
			acceleration = -global_transform.basis.z * engine_power*2	
		else:
			acceleration = -global_transform.basis.z * engine_power
	if braking:
		# brakes
		acceleration += -global_transform.basis.z * braking_power

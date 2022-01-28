# based on http://kidscancode.org/godot_recipes/3d/kinematic_car/car_base/
extends CharacterBody3D

@export var gravity = -20.0
@export var wheel_base = 0.6
@export var steering_limit = 10.0
@export var engine_power = 6.0
@export var braking_power = -9.0
@export var friction = -2.0
@export var drag = -2.0
@export var max_speed_reverse = 3.0

var acceleration = Vector3.ZERO
var velocity = Vector3.ZERO
var steer_angle = 0.0
var forward_vec

# my stuff starts here
var debug = false

var STEER_LIMIT = 0.4 #23 degrees # usually up to 30 deg
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
var reverse = false
var on_ground = true

var offset
var position_on_line

#lights
var headlight_one
var headlight_two
var taillights
var tail_mat

var sparks

var flip_mat = preload("res://assets/car/car_red.tres")

@onready var front_ray = $FrontRay
@onready var rear_ray = $RearRay

func _ready():
	sparks = load("res://objects/Particles_sparks.tscn")
	
	#get lights
	headlight_one = get_node(^"SpotLight3D")
	headlight_two = get_node(^"SpotLight1")
	taillights = get_node(^"taillights")
	
	# setup properties
	set_max_slides(1)

func _physics_process(delta):	
	
	#if is_on_floor(): 	# gives false negatives
	
	if front_ray.is_colliding() or rear_ray.is_colliding():
		on_ground = true
	else:
		on_ground = false
	
	if on_ground:
		get_input()
		apply_friction(delta)
		calculate_steering(delta)
	# fix accumulating acceleration while not on ground
	else:
		acceleration = Vector3.ZERO
		apply_friction(delta)
	#print("is on ground: ", on_ground)
	
	#acceleration.y = 0
	acceleration.y = gravity
	velocity += acceleration * delta # delta is unnecessary for move and collide?
	
	#if debug: print("acc*delta" + str(acceleration*delta) + " len: ", str((acceleration*delta).length()))
	
	# Set our velocity to a new variable (hvel) and remove the Y velocity.
	var hvel = velocity
	if on_ground:
		hvel.y = 0
	
	# velocity, up, snap, slope, slides
	self.set_motion_velocity(hvel)
	
	# TODO: This information should be set to the CharacterBody properties instead of arguments.
	move_and_slide() #hvel, #velocity,
				#-transform.basis.y, Vector3.UP, true, 1)
	
	# Align with slopes
	# If either wheel is in the air, align to slope
	if front_ray.is_colliding() or rear_ray.is_colliding():
		# If one wheel is in air, move it down
		var nf = front_ray.get_collision_normal() if front_ray.is_colliding() else Vector3.UP
		var nr = rear_ray.get_collision_normal() if rear_ray.is_colliding() else Vector3.UP
		var n = ((nr + nf) / 2.0).normalized()
		var xform = align_with_y(global_transform, n)
		global_transform = global_transform.interpolate_with(xform, 0.1)
				
	speed = velocity.length()
	#reverse
	if (velocity.dot(-global_transform.basis.z) > 0) or velocity.length() < 0.05:
		reverse = false
	else:
		reverse = true
	
	# sparks
	var slide_count = get_slide_collision_count()
	if slide_count:
		trigger_sparks()
	
	after_move()

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

func apply_friction(delta):
	# Stop coasting if velocity is very low.
	#if velocity.length() < 0.2 and acceleration.length() == 0:
	#	velocity.x = 0
	#	velocity.z = 0
	
	# fix for AI getting stuck when starting
	if velocity.length() < 1:
		return	
		
	# Friction is proportional to velocity.	
	var friction_force = velocity * friction * delta
	# Drag is proportional to velocity squared.
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

# this is the local version (all except racers)
func calculate_steering(delta):
	steer_angle = get_steering_angle(steer_target, delta)
	
	# Using bicycle model (one front/rear wheel)
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
	
	# Point in the steering direction.
	# this uses global parameters	
	look_at(global_transform.origin + new_heading, Vector3.UP)

func get_input():
	# Override this in inherited scripts for controls
	pass

func after_move():
	# Override in inherited scripts
	pass

func setHeadlights(on):
	if (on):
		headlight_one.set_visible(true)
		headlight_two.set_visible(true)
	else:
		headlight_one.set_visible(false)
		headlight_two.set_visible(false)

func position_line(start_i, end_i, point, path):
	var start = path[start_i]
	var end = path[end_i]
	
	# get the point on line closest to the point
	var px = end.x-start.x
	var py = end.z-start.z

	var something = px*px + py*py

	if something != 0:
		var u =  ((point.x - start.x) * px + (point.z - start.z) * py) / float(something)
	
		if u > 1:
			u = 1
		elif u < 0:
			u = 0
	
		var x = start.x + u * px
		var y = start.z + u * py
	
		return [Vector3(x, start.y, y), start_i, end_i]	
	# need this because division by zero
	else:
		var dist = 0
		return [Vector3(0, start.y, 0), start_i, end_i]

# -------------------------
func trigger_sparks():
	#for index in get_slide_count():
	# because we only attempt 1 slide
	var collision = get_slide_collision(0)
	
	#print(collision.collider.get_parent().get_name())
	var nam = collision.get_collider().get_parent().get_name()
	#print(nam)
	# ignore ground or road "collisions"
	if "Ground" in nam or "Road" in nam:
		#print("Ignoring because ground or road")
		pass
	else:
	
		var c_pos = collision.get_position()
		
		var normal = collision.get_normal()
		#print("Local pos of contact: " + str(l_pos) + " collider " + str(c_pos))
		
		
		var local
		
		# bug! sometimes there are weird "collisions" far away, ignore them
		#if l_pos != c_pos:
		#	pass
			#var g_pos = tr * (l_pos)
			#print("Global pos of collision" + str(g_pos))
		
			#local = g_pos * get_global_transform()
		#else:
			#pass
		local = c_pos * get_global_transform()
		#print("Local" + str(local))

		if local != null:
			var x_gr
			if local.x < 0:
				x_gr = -9.8
				#normal = Vector3(-9.8, 0, -4.5)
			else:
				x_gr = 9.8
				#normal = Vector3(9.8, 0, -4.5)
			
			var y_gr
			if local.z > 0:
				y_gr = -9.8
			else:
				y_gr = -4.5
			
			normal = Vector3(x_gr, 0, y_gr)
			
			
			#var normal = Vector3(-9.8, 0,0)
			#print(str(local))
			#debug_cube(local)
			spawn_sparks(local, normal)

func kill_sparks():	
	# kill old cubes
	for c in get_children():
		if String(c.get_name()).find("Spark") != -1:
	#if get_node(^"Debug") != null:
			c.queue_free()
			
func spawn_sparks(loc, normal):
	var spark = sparks.instantiate()
	
	add_child(spark)
	spark.set_name("Spark")
	spark.set_position(loc)
	spark.set_emitting(true)
	#print("Normal " + str(normal))
	spark.get_process_material().set_gravity(normal)
	# set timer
	spark.get_node(^"Timer").start()

# debug
func debug_cube(loc, red=false):
	var mesh = BoxMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance3D.new()
	node.set_mesh(mesh)
	if red:
		node.get_mesh().surface_set_material(0, flip_mat)
	node.set_cast_shadows_setting(0)
	node.set_name("Debug")
	add_child(node)
	node.set_position(loc)

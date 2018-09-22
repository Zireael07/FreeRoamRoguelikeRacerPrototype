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
var angle = 0
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
var pt_locs_rel = []

var elapsed_secs = 0
var start_secs = 1
var emitted = false
signal path_gotten

# FSM
onready var state = DrivingState.new(self)
var prev_state

const STATE_PATHING = 0
const STATE_DRIVING  = 1


signal state_changed

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

# fsm
func set_state(new_state):
	# if we need to clean up
	#state.exit()
	prev_state = get_state()
	
#	if new_state == STATE_PATHING:
#		state = PathingState.new(self)
#	el
	if new_state == STATE_DRIVING:
		state = DrivingState.new(self)
	
	emit_signal("state_changed", self)

func get_state():
	if state is DrivingState:
		return STATE_DRIVING

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
	
	#if doing nothing because close to target, yellow
	if (rel_loc.distance_to(compare_pos) < 3):
		get_parent().draw.draw_line_color(points, 3, Color(1,1,0,1))
	#if braking, draw red line
	elif not is_enough_dist(rel_loc, compare_pos, speed):  #(round(rel_loc.distance_to(compare_pos)) < round(speed)):
		get_parent().draw.draw_line_color(points, 3, Color(1,0,0,1))
	else:
		get_parent().draw.draw_line_color(points, 3, Color(0,0,1,1))
		

func debug_draw_path(pt_locs):
	if pt_locs.size() > 0:
		get_parent().draw.draw_line_color(pt_locs, 6, Color(1,0,0,1))

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
		if (path != null and path.size() > 0 and not emitted):
			emitted = true
			
			emit_signal("path_gotten")
			
			# stuff to do after getting path
#			print("We have a path to follow")
			for index in range(path.size()):
				if (index > 0): #because #0 is our own location
					target_array.push_back(path[index])

			#var pt_locs_rel = []
			for pt in path:
				#var pt_gl = get_global_transform().xform(pt)
				pt_locs_rel.push_back(get_parent().get_global_transform().xform_inv(pt))
				
			# debug
			for i in pt_locs_rel.size()-1:
				var pt_loc = pt_locs_rel[i]
				get_parent().debug_cube(pt_loc)

		# debug
		if (get_parent().draw != null):
			#debug_draw_lines()
			debug_draw_path(pt_locs_rel)
			
		if (get_parent().draw_arc != null):
			if angle > 0:
				# the minus is there solely for display purposes
				get_parent().draw_arc.draw_arc_poly(get_translation(), 90-get_rotation_degrees().y, -rad2deg(angle), Color(1,0,0))
			else:
				get_parent().draw_arc.draw_arc_poly(get_translation(), 90-get_rotation_degrees().y, -rad2deg(angle), Color(0,1,0))

# just call the state
func _physics_process(delta):
	state.update(delta)
	
# states ----------------------------------------------------
class DrivingState:
	var car
	
	func _init(car):
		self.car = car
		
	func update(delta):
		car.flag = ""
		
		# reset input
		car.gas = false
		car.braking = false
		car.left = false
		car.right = false

		#data
		car.speed = car.get_linear_velocity().length();
		var forward_vec = car.get_translation() + car.get_global_transform().basis.z
		
		car.rel_loc = car.get_global_transform().xform_inv(car.get_target(car.current))
		
		#2D angle to target (local coords)
		car.angle = atan2(car.rel_loc.x, car.rel_loc.z)
		
		#is the target in front of us or not?
		var pos = car.get_global_transform().origin
		#B-A = from A to B
		var target_vec = car.get_target(car.current) - pos
		car.dot = forward_vec.dot(target_vec)
		
		# needed for race position
		if car.path != null and car.path.size() > 0:
			car.position_on_line = car.position_line(car.prev, car.current, pos, car.path)
		
		#BEHAVIOR
		
		#if we're over the limit, relax steering
		car.limit = car.get_steering_limit()
		if (car.get_steering() > car.limit):
			car.left = true
		if (car.get_steering() < -car.limit):
			car.right = true
	
	
		#stop if we're supposed to
		if (car.stop):
			car.stopping()
		else:
			# detect collisions
			car.collision_avoidance()
						
			
			if not (car.flag.find("AVOID") != -1):
				# go back on track if too far away from the drive line
				car.go_back(pos)
				
				if not car.flag == "GOING BACK":
					#handle gas/brake
					if car.is_enough_dist(car.rel_loc, car.compare_pos, car.speed):
						if (car.speed < car.top_speed):
							car.gas = true
					else:
						if (car.speed > 1):
							car.braking = true
			
					#if we're close to target, do nothing
					if (car.rel_loc.distance_to(car.compare_pos) < 3) and abs(car.angle) < 0.9:
						#fixed_angling()
						#print("Close to target, don't deviate")
						#relax steering
						if (abs(car.get_steering()) > 0.02):
							car.left = false
							car.right = false
						
					else:
						#normal stuff
						car.fixed_angling()
		
		# predict wheel angle
		car.predicted_steer = car.predict_steer(delta, car.left, car.right)
		
		car.process_car_physics(delta, car.gas, car.braking, car.left, car.right)
		
		#if we passed the point, don't backtrack
		if (car.dot < 0 and not car.stop):
			##do we have a next point?
			if (car.target_array.size() > car.current+1):
				car.prev = car.current
				car.current = car.current + 1
			else:
				#print("We're at the end")
				car.stop = true
		
		
		if (car.rel_loc.distance_to(Vector3(0,1.5,0)) < 2):
			#print("We're close to target")
			
			##do we have a next point?
			if (car.target_array.size() > car.current+1):
				car.prev = car.current
				car.current = car.current + 1
			else:
				#print("We're at the end")
				car.stop = true

#-------------------------------------------

# AI	
	
func stopping():
	#relax steering
	if (abs(get_steering()) > 0.00):
		left = false
		right = false
		
	if (speed > 0.1 and not reverse):
		braking = true
	if (speed > 0.1 and reverse):
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
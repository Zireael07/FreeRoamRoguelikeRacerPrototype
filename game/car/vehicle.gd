
extends VehicleBody

# Member variables
#const STEER_LIMIT = 1 #radians
const MAX_SPEED = 55 #m/s = 200 kph
#var steer_inc = 0.02 #radians
const STEER_SPEED = 1
const STEER_LIMIT = 0.4

export var force = 1500
var braking_force_mult = 4

var offset

#steering
var steer_angle = 0
var steer_target = 0
# this is mostly used by the AI but might be a curiosity for the player
var predicted_steer = 0

#speed
var speed
var speed_int = 0
var speed_kph = 0

var forward_vec
var reverse

#lights
var headlight_one
var headlight_two
var taillights
var tail_mat

func process_car_physics(delta, gas, braking, left, right):
	speed = get_linear_velocity().length();
	
	#vary limit depending on current speed
	if (speed > 35): ##150 kph
		STEER_LIMIT = 0.1
		STEER_SPEED = 0.2
	elif (speed > 28): ##~100 kph
		STEER_LIMIT = 0.1
		STEER_SPEED = 0.3
	elif (speed > 15): #~50 kph
		STEER_LIMIT = 0.3
		STEER_SPEED = 0.4
	elif (speed > 5): #~25 kph
		STEER_LIMIT = 0.5
		STEER_SPEED = 0.4
	elif (speed > 2): #10 kph
		STEER_LIMIT = 0.75
		STEER_SPEED = 0.5
	else:
		STEER_LIMIT = 1
		STEER_SPEED = 1
	
	if (left):
		steer_target = STEER_LIMIT
	elif (right):
		steer_target = -STEER_LIMIT
	else: #if (not left and not right):
		steer_target = 0
	
	#gas
	if (gas): #(Input.is_action_pressed("ui_up")):
		#obey max speed setting
		if (speed < MAX_SPEED):
			set_engine_force(force)
		else:
			set_engine_force(0)
	else:
		if (speed > 3):
			set_engine_force(-force/4)
		else:
			set_engine_force(0)
	
	#cancel braking visual
	tail_mat = taillights.get_mesh().surface_get_material(0)
	if tail_mat != null:
		tail_mat.set_albedo(Color(0.62,0.62,0.62))
	
	#brake/reverse
	if (braking): #(Input.is_action_pressed("ui_down")):
		if (speed > 5):
			#slows down 1 unit per tick
			# increasing the value seems to do nothing
			set_brake(1)
			# let's make the brake actually brake harder
			set_engine_force(-force*braking_force_mult)
		else:
			#reverse
			set_brake(0.0)
			set_engine_force(-force)
			
		#visual effect
		if tail_mat != null:	
			tail_mat.set_albedo(Color(1,1,1))
		
	else:
		set_brake(0.0)
	
	#steering
	if (steer_target < steer_angle):
		steer_angle -= STEER_SPEED*delta
		if (steer_target > steer_angle):
			steer_angle = steer_target
	elif (steer_target > steer_angle):
		steer_angle += STEER_SPEED*delta
		if (steer_target < steer_angle):
			steer_angle = steer_target
	
	set_steering(steer_angle)
	
	#this one actually reacts to rotations unlike the one using basis.z or linear velocity.z
	var forward_vec = get_global_transform().xform(Vector3(0, 1.5, 2))-get_global_transform().origin
	#reverse
	if (get_linear_velocity().dot(forward_vec) > 0):
		reverse = false
	else:
		reverse = true
	
	
func _physics_process(delta):
	#just to have something here
	var basis = get_transform().basis.y

func reset_car():
	var reset_rot = Vector3(0, get_rotation_degrees().y, 0)
	set_rotation_degrees(reset_rot)

# basically copy-pasta from the car physics function, to predict steer the NEXT physics tick
func predict_steer(delta, left, right):
	if (left):
		steer_target = STEER_LIMIT
	elif (right):
		steer_target = -STEER_LIMIT
	else: #if (not left and not right):
		steer_target = 0
	
	
	if (steer_target < steer_angle):
		steer_angle -= STEER_SPEED*delta
		if (steer_target > steer_angle):
			steer_angle = steer_target
	elif (steer_target > steer_angle):
		steer_angle += STEER_SPEED*delta
		if (steer_target < steer_angle):
			steer_angle = steer_target
			
	return steer_angle


# this works in 2d (disregards the height)
func offset_dist(start, end, point):
	#print("Cross dist: " + str(start) + " " + str(end) + " " + str(point))
	# 2d
	#x1, y1 = start.x, start.y
	#x2, y2 = end.x, end.y
	#x3, y3 = point.x, point.y

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
	
		var dx = x - point.x
		var dy = y - point.z
	
	    # Note: If the actual distance does not matter,
	    # if you only want to compare what this function
	    # returns to other results of this function, you
	    # can just return the squared distance instead
	    # (i.e. remove the sqrt) to gain a little performance
	
		var dist = sqrt(dx*dx + dy*dy)
	
		return [dist, Vector3(x, start.y, y)]
	# need this because division by zero
	else:
		var dist = 0
		return [dist, Vector3(0, start.y, 0)]
	

func _ready():
	#get lights
	headlight_one = get_node("SpotLight")
	headlight_two = get_node("SpotLight1")
	taillights = get_node("taillights")
	
func setHeadlights(on):
	if (on):
		headlight_one.set_visible(true)
		headlight_two.set_visible(true)
	else:
		headlight_one.set_visible(false)
		headlight_two.set_visible(false)
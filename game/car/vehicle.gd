
extends VehicleBody

# Member variables
#const STEER_LIMIT = 1 #radians
const MAX_SPEED = 55 #m/s = 200 kph
#var steer_inc = 0.02 #radians
const STEER_SPEED = 1
const STEER_LIMIT = 0.4

export var engine_force = 40

#steering
var steer_angle = 0
var steer_target = 0

#speed
var speed
var speed_int = 0
var speed_kph = 0

var reverse

#lights
var headlight_one
var headlight_two

func process_car_physics(delta, gas, brake, left, right):
	speed = get_linear_velocity().length();
	
	#vary limit depending on current speed
	if (speed > 35): ##150 kph
		STEER_LIMIT = 0.2
		STEER_SPEED = 0.5
	elif (speed > 28): ##~100 kph
		STEER_LIMIT = 0.4
		STEER_SPEED = 0.5
	elif (speed > 15): #~50 kph
		STEER_LIMIT = 0.5
		STEER_SPEED = 0.5
	elif (speed > 5): #~25 kph
		STEER_LIMIT = 0.75
		STEER_SPEED = 0.5
	else:
		STEER_LIMIT = 1
		STEER_SPEED = 1
	
	if (left):
		steer_target = -STEER_LIMIT
	elif (right):
		steer_target = STEER_LIMIT
	else: #if (not left and not right):
		steer_target = 0
	
	#gas
	if (gas): #(Input.is_action_pressed("ui_up")):
		#obey max speed setting
		if (speed < MAX_SPEED):
			set_engine_force(engine_force)
		else:
			set_engine_force(0)
	else:
		if (speed > 3):
			set_engine_force(-engine_force/4)
		else:
			set_engine_force(0)
	
	#brake/reverse
	if (brake): #(Input.is_action_pressed("ui_down")):
		if (speed > 5):
			#slows down 1 unit per tick
			set_brake(1)
		else:
			#reverse
			set_brake(0.0)
			set_engine_force(-engine_force)
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
	
	#reverse
	if (get_linear_velocity().z > 0):
		reverse = false
	else:
		reverse = true
	
	
func _fixed_process(delta):
	#just to have something here
	var basis = get_transform().basis.y


func _ready():
	#get lights
	headlight_one = get_node("SpotLight")
	headlight_two = get_node("SpotLight1")
	
func setHeadlights(on):
	if (on):
		headlight_one.set_enabled(true)
		headlight_two.set_enabled(true)
	else:
		headlight_one.set_enabled(false)
		headlight_two.set_enabled(false)
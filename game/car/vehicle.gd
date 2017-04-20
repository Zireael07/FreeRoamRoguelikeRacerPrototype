
extends VehicleBody

# Member variables
const STEER_LIMIT = 1 #radians
var steer_inc = 0.02 #radians


export var engine_force = 40

#speed
var speed

func _fixed_process(delta):
	speed = get_linear_velocity().length();
	
	#gas
	if (Input.is_action_pressed("ui_up")):
		set_engine_force(engine_force)
	else:
		if (speed > 3):
			set_engine_force(-engine_force/4)
		else:
			set_engine_force(0)
	
	#brake/reverse
	if (Input.is_action_pressed("ui_down")):
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
	if (Input.is_action_pressed("ui_left") and get_steering() > -STEER_LIMIT):
		set_steering(get_steering()-steer_inc)
	if (Input.is_action_pressed("ui_right") and get_steering() < STEER_LIMIT):
		set_steering(get_steering()+steer_inc)



func _ready():
	set_fixed_process(true)

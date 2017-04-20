
extends VehicleBody

# Member variables
const STEER_LIMIT = 1 #radians
var steer_inc = 0.02 #radians


export var engine_force = 40

#speed
var speed
var speed_int = 0
var speed_kph = 0

#hud
var hud
var speed_text

func _fixed_process(delta):
	speed = get_linear_velocity().length();
	
	#speedometer
	speed_int = round(speed)
	speed_kph = round(speed_int*3.6)
	speed_text = String(speed_int) + " m/s " + String(speed_kph) + " kph"
	hud.update_speed(speed_text)
	
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
	##GUI
	var h = preload("res://hud/hud.tscn")
	hud = h.instance()
	add_child(hud)
	
	set_fixed_process(true)

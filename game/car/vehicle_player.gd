extends "vehicle.gd"

# class member variables go here, for example:
#hud
var hud
var speed_text

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	##GUI
	var h = preload("res://hud/hud.tscn")
	hud = h.instance()
	add_child(hud)
	
	set_fixed_process(true)

func _fixed_process(delta):
	#input
	var gas = false
	var brake = false
	var left = false
	var right = false
	
	#fps display
	hud.update_fps()
	
	if (Input.is_action_pressed("ui_up")):
		gas = true
	
	if (Input.is_action_pressed("ui_down")):
		brake = true
	
	if (Input.is_action_pressed("ui_left")):
		left = true
	if (Input.is_action_pressed("ui_right")):
		right = true
		
	#make physics happen!
	process_car_physics(gas, brake, left, right)
	
	
	#speedometer
	speed_int = round(speed)
	speed_kph = round(speed_int*3.6)
	speed_text = String(speed_int) + " m/s " + String(speed_kph) + " kph"
	hud.update_speed(speed_text)
	
	
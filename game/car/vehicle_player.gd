extends "vehicle.gd"

# class member variables go here, for example:
#hud
var hud
var speed_text

var last_pos
var distance = 0
var distance_int = 0

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	##GUI
	var h = preload("res://hud/hud.tscn")
	hud = h.instance()
	add_child(hud)
	
	last_pos = get_translation()
	
	set_fixed_process(true)
	set_process_input(true)

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
	speed_kph = round(speed*3.6)
	speed_text = String(speed_int) + " m/s " + String(speed_kph) + " kph"
	hud.update_speed(speed_text)
	
	#increment distance counter
	distance = distance + get_translation().distance_to(last_pos)
	last_pos = get_translation()
	
	distance_int = round(distance)
	#update distance HUD
	hud.update_distance("Distance: " + String(distance_int) + " m")
	
#doesn't interact with physics
func _input(event):
	if (Input.is_action_pressed("headlights_toggle")):
		if (get_node("SpotLight").is_enabled()):
			setHeadlights(false)
		else:
			setHeadlights(true)	

extends "vehicle.gd"

# class member variables go here, for example:
#hud
var hud
var speed_text
var map
var panel

var last_pos
var distance = 0
var distance_int = 0

# setup stuff
var elapsed_secs = 0
var start_secs = 2
var emitted = false

signal load_ended

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	# our custom signal
	connect("load_ended", self, "on_load_ended")
	
	##GUI
	var h = preload("res://hud/hud.tscn")
	hud = h.instance()
	add_child(hud)
	var m = preload("res://hud/minimap.tscn")
	map = m.instance()
	add_child(map)
	
	var msg = preload("res://hud/message_panel.tscn")
	panel = msg.instance()
	panel.set_name("Messages")
	#panel.set_text("Welcome to 大都市")
	add_child(panel)
	panel.set_text("Welcome to 大都市")
	
	last_pos = get_translation()
	
	set_physics_process(true)
	set_process_input(true)

func on_load_ended():
	print("Loaded all pertinent stuff")

func _physics_process(delta):
	# emit a signal when we're all set up
	elapsed_secs += delta
	if (elapsed_secs > start_secs and not emitted):
		emit_signal("load_ended")
		emitted = true
	
	
	#input
	var gas = false
	var braking = false
	var left = false
	var right = false
	
	#fps display
	hud.update_fps()
	
	if (Input.is_action_pressed("ui_up")):
		gas = true
	
	if (Input.is_action_pressed("ui_down")):
		braking = true
	
	if (Input.is_action_pressed("ui_left")):
		left = true
	if (Input.is_action_pressed("ui_right")):
		right = true
		
	#make physics happen!
	process_car_physics(delta, gas, braking, left, right)
	
	#reset
	if (Input.is_action_pressed("steer_reset")):
		reset_car()
	
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
	
	if (Input.is_action_pressed("camera_debug")):
		var cam = get_child(6).get_child(0)
		if (cam !=null):
			if (not cam.debug):
				cam.set_debug(true)
			else:
				cam.set_debug(false)
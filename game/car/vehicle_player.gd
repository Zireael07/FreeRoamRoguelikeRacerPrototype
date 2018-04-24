extends "vehicle.gd"

# class member variables go here, for example:
var World_node
	
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

var cockpit_cam
var cam_speed = 1
var cockpit_cam_target_angle = 0
var cockpit_cam_angle = 0
var cockpit_cam_max_angle = 5
var peek

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	# our custom signal
	connect("load_ended", self, "on_load_ended")
	
	World_node = get_parent().get_parent().get_node("World")
	cockpit_cam = $"cambase/CameraCockpit"
	
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
	
	
	var pause = preload("res://hud/pause_panel.tscn")
	var pau = pause.instance()
	add_child(pau)
	
	last_pos = get_translation()
	
	set_physics_process(true)
	set_process(true)
	set_process_input(true)

func on_load_ended():
	print("Loaded all pertinent stuff")

func _physics_process(delta):
	# were we peeking last tick?
	var old_peek = peek
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
	
	peek = false
	
	if (Input.is_action_pressed("ui_up")):
		gas = true
	
	if (Input.is_action_pressed("ui_down")):
		braking = true
	
		# camera
	if Input.is_action_pressed("peek_left"):
		peek = true
		#print("Peek left")
		if cockpit_cam.is_current():
			cockpit_cam_target_angle = 30
	
	if Input.is_action_pressed("peek_right"):
		peek = true
		#print("Peek right")
		if cockpit_cam.is_current():
			cockpit_cam_target_angle = -40
	
	
	# turning
	if (Input.is_action_pressed("ui_left")):
		left = true
		
		# tilt cam
		if cockpit_cam.is_current() and cockpit_cam_target_angle > -11:
			cockpit_cam_target_angle += 1
		
		
	if (Input.is_action_pressed("ui_right")):
		right = true
		
		# tilt cam
		if cockpit_cam.is_current() and cockpit_cam_target_angle < 11:
			cockpit_cam_target_angle -= 1
	
	# reset cam
	if not left and not right and not peek:
		# if we were peeking last frame but are not now
		if old_peek and cockpit_cam.is_current():
			cockpit_cam_angle = 0
			#print("Old peek is: " + str(old_peek))
		
		# reset cam
		if cockpit_cam.is_current():
			cockpit_cam_target_angle = 0
	
	# vary cam speed
	var speed = get_linear_velocity().length()
	
	cam_speed = 1
	if speed > 25:
		cam_speed = 4
	if speed > 15:
		cam_speed = 3
	else:
		cam_speed = 2
		
	if peek:
		cam_speed = 30
		
	#rotate cam
	# left
	if (cockpit_cam_target_angle < cockpit_cam_angle):
		cockpit_cam_angle -= cam_speed*delta
		if (cockpit_cam_target_angle > cockpit_cam_max_angle):
			print("Setting to target angle: " + str(cockpit_cam_target_angle))
			cockpit_cam_angle = cockpit_cam_target_angle
	# right
	if (cockpit_cam_target_angle > cockpit_cam_angle):
		cockpit_cam_angle += cam_speed*delta
		# bugs
		#if (cockpit_cam.target_angle < cockpit_cam.max_angle):
		#	print("Setting to target angle: " + str(cockpit_cam.target_angle))
		#	cockpit_cam.angle = cockpit_cam.target_angle
	
	cockpit_cam.set_rotation_degrees(Vector3(180,cockpit_cam_angle, 180))
	
		
	#make physics happen!
	process_car_physics(delta, gas, braking, left, right)
	
	#reset
	if (Input.is_action_pressed("steer_reset")):
		reset_car()
	
# UI stuff doesn't have to be in physics_process
func _process(delta):
	#fps display
	hud.update_fps()
	
	#speedometer
	speed_int = round(speed)
	speed_kph = round(speed*3.6)
	speed_text = String(speed_int) + " m/s " + String(speed_kph) + " kph"
	hud.update_speed(speed_text)
	
	
	hud.update_wheel_angle(get_steering(), 1) #absolute maximum steer limit
	hud.update_angle_limiter(STEER_LIMIT)
	
	# in-game time
	var text = " "
	if (World_node != null):
		text = String(World_node.hour) + " : " + String(round(World_node.minute))
	
	hud.update_clock(text)
	
	#increment distance counter
	distance = distance + get_translation().distance_to(last_pos)
	last_pos = get_translation()
	
	distance_int = round(distance)
	#update distance HUD
	hud.update_distance("Distance: " + String(distance_int) + " m")

	#print("Light color" + str(World_node.light_color))
	if "light_color" in World_node and World_node.light_color != null:
		var color = Vector3(World_node.light_color.r, World_node.light_color.g, World_node.light_color.b)
	#print("Color input: " + str(color))
		get_node("skysphere/Skysphere").get_material_override().set_shader_param("light", color) #Color(World_node.light_color.r, World_node.light_color.g, World_node.light_color.b))
	#print("Shader color: " + str(get_node("skysphere/Skysphere").get_material_override().get_shader_param("light")))
	
	if speed > 28: #100 kphs
		get_node("cambase/Camera/blur_quad").set_visible(true)
		#get_mesh().surface_get_material(0).set_shader_param
	else:
		get_node("cambase/Camera/blur_quad").set_visible(false)
	
#doesn't interact with physics
func _input(event):
	if (Input.is_action_pressed("headlights_toggle")):
		if (get_node("SpotLight").is_visible()):
			setHeadlights(false)
		else:
			setHeadlights(true)	
	
	# switch cameras
	if (Input.is_action_pressed("camera")):
		var chase_cam = get_node("cambase/Camera")
		var cockpit_cam = get_node("cambase/CameraCockpit")
		if chase_cam.is_current():
			cockpit_cam.make_current()
		else:
			chase_cam.make_current()
	
	
	
	if (Input.is_action_pressed("camera_debug")):
		var cam = get_node("cambase/Camera")
		if (cam !=null):
			if (not cam.debug):
				cam.set_debug(true)
			else:
				cam.set_debug(false)
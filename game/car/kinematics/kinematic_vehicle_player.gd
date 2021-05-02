extends "res://car/kinematics/kinematic_vehicle.gd"

# majority of this is copy-pasted from the non-kinematic version
# I wish Godot could inherit from two scripts at once
var health = 100
var battery = 50

var World_node
var map

#hud
var hud
var speed_text
var minimap
var map_big
var panel
var game_over
var vjoy

var mouse_steer = false

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

var skidmark = null

func _ready():
	# our custom signal
	connect("load_ended", self, "on_load_ended")

	World_node = get_parent().get_parent().get_node("scene")
	cockpit_cam = $"cambase/CameraCockpit"
	#debug_cam = $"cambase/CameraDebug"

	##GUI
	var h = preload("res://hud/hud.tscn")
	hud = h.instance()
	add_child(hud)

	var v = preload("res://hud/virtual_joystick.tscn")
	vjoy = v.instance()
	vjoy.set_name("Joystick")
	# we default to mouse steering off
	vjoy.hide()
	add_child(vjoy)


	# get map seed
	map = get_parent().get_parent().get_node("map")
	if map != null:
		hud.update_seed(map.get_node("triangulate/poisson").seed3)

	#var m = preload("res://hud/minimap.tscn")
#	var m = preload("res://hud/Viewport.tscn")
#	minimap = m.instance()
#	minimap.set_name("Viewport_root")
#	add_child(minimap)
#	minimap.set_name("Viewport_root")

#	m = preload("res://hud/MapView.tscn")
#	map_big = m.instance()
#	map_big.set_name("Map")
#	# share the world with the minimap
#	map_big.get_node("Viewport").world_2d = get_node("Viewport_root/Viewport").world_2d
#	add_child(map_big)
#	map_big.hide()


	var msg = preload("res://hud/message_panel.tscn")
	panel = msg.instance()
	panel.set_name("Messages")
	#panel.set_text("Welcome to 大都市")
	add_child(panel)

	# random date
	var date = random_date()
	var date_format_west = "%d-%d-%d"
	var date_west = date_format_west % [date[0], date[1], date[2]]
	var date_format_east = "未来%d年 %d月 %d日"
	# year-month-day
	var date_east = date_format_east % [date[2]-2018, date[1], date[0]]

	panel.set_text("Welcome to 大都市" + "\n" + "The date is: " + date_east + " (" + date_west+")" + "\n" +
	"Enjoy your new car! Remember, it's electric so you don't have to worry about gearing, but you have to watch your battery level!")


	var pause = preload("res://hud/pause_panel.tscn")
	var pau = pause.instance()
	add_child(pau)

	game_over = preload("res://hud/game_over.tscn")

	# distance
	last_pos = get_translation()

	skidmark = preload("res://objects/skid_mark.tscn")

func random_date():
	# seed the rng
	randomize()

	var day = (randi() % 30) +1
	var month = (randi() % 13) +1
	var year = 2040 + (randi() % 20)

	return [day, month, year]

func on_load_ended():
	print("Loaded all pertinent stuff")
	# enable our cam
	var chase_cam = get_node("cambase/Camera")
	chase_cam.make_current()
	# disable rear view mirror
	$"cambase/MirrorMesh".set_visible(false)
	$"cambase/Viewport/CameraCockpitBack".clear_current()
	$"cambase/Viewport".set_update_mode(Viewport.UPDATE_DISABLED)

	# temporarily disable
	#get_node("driver_new").setup_ik()

	# optimize label/nameplate rendering
	get_node("..").freeze_viewports()

# ----------------------------------------------------------------
# kinematic driving
func get_input():
	var turn = Input.get_action_strength("steer_left")
	turn -= Input.get_action_strength("steer_right")
	steer_angle = turn * deg2rad(steering_limit)
	$tmpParent/sedanSports/Spatial_FL.rotation.y = steer_angle*2
	$tmpParent/sedanSports/Spatial_FR.rotation.y = steer_angle*2
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("accelerate"):
		acceleration = -transform.basis.z * engine_power
	if Input.is_action_pressed("brake"):
		acceleration = -transform.basis.z * braking

# --------------------------------------------------
func get_compass_heading():
	# because E and W were easiest to identify (the sun)
	# this relied on Y rotation
	#var ang_to_dir = {180: "E", -180: "E", 0: "W", 90: "N", -90: "S"}
	# this relies on angle to marker
	var ang_to_dir = {180: "N", -180: "N", 0: "S", 90: "E", -90: "W"}

	# -180 -90 0 90 180 are the possible angles
	# this matches Y rot ang_to_dir above
	#var num_to_dir = {0: "E", 1:"S", 2:"W", 3:"N", 4:"E"}
	var num_to_dir = {0:"N", 1: "NW", 2:"W", 3: "SW", 4:"S", 5: "SE", 6:"E", 7: "NE", 8:"N"}
	# map from -180-180 to 0-4
	#var rot = get_rotation_degrees().y
	var rot = rad2deg(get_heading())
	var num_mapping = range_lerp(rot, -180, 180, 0, 8)
	var disp = num_to_dir[int(round(num_mapping))]
	
	return disp

func get_heading():
	var forward_global = get_global_transform().xform(Vector3(0, 0, 2))
	var forward_vec = forward_global-get_global_transform().origin
	#var basis_vec = player.get_global_transform().basis.z
	
	# looks like this is always positive?!
	#var player_rot = forward_vec.angle_to(Vector3(0,0,1))
	# returns radians
	#return player_rot
	var North = get_node("/root/Navigation/marker_North")
	var rel_loc = get_global_transform().xform_inv(North.get_global_transform().origin)
	#2D angle to target (local coords)
	var angle = atan2(rel_loc.x, rel_loc.z)
	#print("Heading: ", rad2deg(angle))
	return angle

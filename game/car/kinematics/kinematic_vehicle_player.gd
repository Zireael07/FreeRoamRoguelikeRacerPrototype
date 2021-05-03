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
#var cam_speed = 1
#var cockpit_cam_target_angle = 0
#var cockpit_cam_angle = 0
#var cockpit_cam_max_angle = 5
#var peek

# racing
var race
var prev = 0
var current = 0
var dot = 0
var rel_loc = Vector3()
var race_path = PoolVector3Array()
var finished = false

# player navigation
var reached_inter
var reached_changed = false
var show_nav_tip = false

var was_tunnel = false # for particles
var was_dirt = false
var was_fast = false

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

	var m = preload("res://hud/Viewport.tscn")
	minimap = m.instance()
	minimap.set_name("Viewport_root")
	add_child(minimap)
	minimap.set_name("Viewport_root")

	m = preload("res://hud/MapView.tscn")
	map_big = m.instance()
	map_big.set_name("Map")
	# share the world with the minimap
	map_big.get_node("Viewport").world_2d = get_node("Viewport_root/Viewport").world_2d
	add_child(map_big)
	map_big.hide()


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
	$tmpParent/Spatial_FL.rotation.y = steer_angle*2
	$tmpParent/Spatial_FR.rotation.y = steer_angle*2
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("accelerate"):
		acceleration = -transform.basis.z * engine_power
		#cancel braking visual
		tail_mat = taillights.get_mesh().surface_get_material(0)
		if tail_mat != null:
			tail_mat.set_albedo(Color(0.62,0.62,0.62))
	if Input.is_action_pressed("brake"):
		acceleration = -transform.basis.z * braking
		#visual effect
		if tail_mat != null:	
			tail_mat.set_albedo(Color(1,1,1))
		

# --------------------------------------------------

func _physics_process(delta):
	# emit a signal when we're all set up
	elapsed_secs += delta
	if (elapsed_secs > start_secs and not emitted):
		emit_signal("load_ended")
		emitted = true

# UI stuff doesn't have to be in physics_process
func _process(delta):
	#fps display
	hud.update_fps()

	#speedometer
	speed_int = round(speed)
	speed_kph = round(speed*3.6)
	#speed_text = String(speed_int) + " m/s " + String(speed_kph) + " kph"
	speed_text = String(speed_kph)
	# make speed reading red if above speed limit
	if speed > 15:
		hud.update_speed(speed_text, Color(1,0,0))
	else:
		hud.update_speed(speed_text, Color(0,1,1)) #cyan


	hud.update_wheel_angle(steer_angle, 1) #absolute maximum steer limit
	hud.update_angle_limiter(0.4) # STEER_LIMIT from physics vehicle, 23 deg

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

	var disp = get_compass_heading()
	hud.update_compass(str(disp))

	# detect what we're driving on
	var hit = get_node("RearRay").get_collider_hit()
	var disp_name = ""
	if hit != null:
		# particles
		was_dirt = false
		get_node("Smoke").set_emitting(false)
		get_node("Smoke2").set_emitting(false)
		
		var road_ = hit.get_parent().get_parent().get_name().find("Road_")
		var road = hit.get_parent().get_parent().get_name().find("Road")
		# straight
		if road_ != -1:
			disp_name = hit.get_parent().get_parent().get_parent().get_parent().get_name()
			reached_changed = false
		elif road != -1:
			disp_name = hit.get_parent().get_parent().get_parent().get_parent().get_parent().get_name()
			reached_changed = false
		# intersection
		else:
			disp_name = hit.get_parent().get_parent().get_name()
			
			# despawn racers elsewhere
			if race == null:
				#print("Not in race")
				var racers = get_tree().get_nodes_in_group("race_AI")
				for r in racers:
					#print(r.romaji + " race end intersection: " + str(r.race_int_path[1]))
					if disp_name.find(str(r.race_int_path[1])) != -1:
						pass
						#print("At race end intersection")
					else:
						print("Not race end intersection")
						r.queue_free()
						# remove minimap marker
						minimap.get_node("Viewport/minimap").remove_arrow(r)
			
			# if we have a player navigation path
			if map_big.int_path.size() > 0:
				# if we haven't reached a new intersection
				if reached_changed == false:
					# ignore #0 in said path
					for i in range(1, map_big.int_path.size()-1):
						var inter = map_big.int_path[i]
						var id = disp_name.lstrip("intersection")
						# if we reached a new intersection on our path, mark it as such
						if int(id) == inter:
							#print("We hit intersection present in path...", inter)
							reached_inter = [inter, i]
							reached_changed = true
							break
				# if we reached a new intersection, tell us where to go
				if reached_changed:
					# angle to next intersection in int_path
					var angle_inter = angle_to_intersection(map_big.int_path[reached_inter[1]+1])
					print("Angle to next intersection: ", angle_inter)
					# pop up navigation helper on HUD	
					if angle_inter < 0:
						hud.update_nav_label("Turn right")
					else:
						hud.update_nav_label("Turn left")
					# hide text if angle very small
					if abs(angle_inter) < 40:
						hud.update_nav_label("")
	# else we're on a dirt ground
	else:
		if not was_dirt:
			was_dirt = true
			get_node("Smoke").set_emitting(true)
			get_node("Smoke2").set_emitting(true)
						
	# clear text if we passed the newly reached intersection				
	if not reached_changed and not show_nav_tip:
		hud.update_nav_label("")

	hud.update_road(str(disp_name) if hit != null else "")

	#hud.update_debug("Player vel: x: " + str(get_linear_velocity().x) + "y: " + str(get_linear_velocity().z))
	#hud.update_debug("Player: " + str(get_rotation_degrees()) + '\n' + " Arrow : " + str(cam_rot))

	hud.update_health(health)

	hud.update_battery(battery)

	# skid marks
	if speed < 5:
		var pos = get_node("cambase/Camera").get_global_transform().origin
		var mark = skidmark.instance()
		var wh_pos = get_node("tmpParent/Spatial_RL")
		var mark_pos = wh_pos.get_global_transform().origin - Vector3(0,0.3, 0) # tiny offset to make marks show on roads
		var lpos = map.to_local(mark_pos)
		mark.set_translation(lpos)
		# place all the skidmarks under a common parent
		var gfx = null
		if !map.has_node("gfx"):
			gfx = Spatial.new()
			gfx.set_name("gfx")
			map.add_child(gfx)
		else:
			gfx = map.get_node("gfx")
			
		gfx.add_child(mark)
		mark.look_at(pos, Vector3(0,1,0))
		# flip around because... +Z vs -Z...
		#mark.rotate_y(deg2rad(180))
		#mark.rotate_x(deg2rad(-90))

		mark = skidmark.instance()
		wh_pos = get_node("tmpParent/Spatial_RR")
		mark_pos = wh_pos.get_global_transform().origin - Vector3(0,0.3, 0) # tiny offset to make marks show on roads
		lpos = map.to_local(mark_pos)
		mark.set_translation(lpos)
		# we should already have the common parent, see above
		gfx.add_child(mark)
		mark.look_at(pos, Vector3(0,1,0))

# -----------------------------------------

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

# -----------------------------------------------
func create_race_path(path):
	print("Creating race path")
	if (path != null and path.size() > 0):
		#print("We have a race path to follow")
		for index in range(path.size()):
			race_path.push_back(path[index])

	# tell the race setup is done
	race.done = true
	print("Race set up is done")

func angle_to_intersection(id):
	# contains intersections global positions
	var intersections = get_node("Viewport_root/Viewport/minimap").intersections
	var pos_gl = intersections[id]
	#print("Global position ", pos_gl)
	var rel_pos = get_global_transform().xform_inv(pos_gl)
	# dummy out the y value
	rel_pos = Vector3(rel_pos.x, 0, rel_pos.z)
	#print("Relative loc of intersection", id, " is ", rel_pos)
	# we don't care about z, only about x
	return rel_pos.x

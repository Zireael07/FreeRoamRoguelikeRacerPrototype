# this is used by both car & bike
extends "vehicle.gd"

# class member variables go here, for example:
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

var debug_cam

# racing
var race
var prev = 0
var current = 0
var dot = 0
var rel_loc = Vector3()
var race_path = PoolVector3Array()
var finished = false

# performance testing
var count
var timer
var perf_distance

var money = 0

# vehicle switching
var car_scene = null
var bike_scene = null

# player navigation
var reached_inter
var reached_changed = false

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	# preload doesn't work since we're loading from a script that both scenes use
	car_scene = load("res://car/car_base.tscn")
	bike_scene = load("res://car/bike_base.tscn")

	# contacts
	set_max_contacts_reported(1)
	set_contact_monitor(true)


	# our custom signal
	connect("load_ended", self, "on_load_ended")

	World_node = get_parent().get_parent().get_node("scene")
	cockpit_cam = $"cambase/CameraCockpit"
	debug_cam = $"cambase/CameraDebug"

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


	last_pos = get_translation()


	set_physics_process(true)
	set_process(true)
	set_process_input(true)
	
	# make the bike more controllable
	if get_parent().is_in_group("bike"):
		STEER_LIMIT = 0.3
		STEER_SENS = 0.5
		SPEED_SENS = 0.9

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

#-------------------------------------------------
# interacting with physics
func _physics_process(delta):
	# were we peeking last tick?
	var old_peek = peek
	# emit a signal when we're all set up
	elapsed_secs += delta
	if (elapsed_secs > start_secs and not emitted):
		emit_signal("load_ended")
		emitted = true

	# performance testing
	if count:
		timer += delta

	if speed > 28:
		count = false
		if timer and timer > 0.0:
			#var perc_str = str((timer/12.0)*100) + "% of 12s (1500 force)"
			print("Reached 100 kph, timer: " + str(timer) + " " + str(perf_distance) + " m " + \
			#"acc: " + str(accel_from_time(timer)) + " m/s^2 " + \
			"acc: " + str(accel_from_data(timer, perf_distance)) + " m/s^2 " + \
			str(time_from_accel(accel_from_data(timer, perf_distance))) + " s")
			# \n " + perc_str)
			timer = 0.0
		#else:
		#	print("Reached 100")


	# racing
	if race and race_path.size() > 0:
		var forward_global = get_global_transform().xform(Vector3(0, 0, 2))
		var forward_vec = forward_global-get_global_transform().origin

		var pos = get_global_transform().origin
		#B-A = from A to B
		var target_vec = race_path[current] - pos
		# forward vec goes from origin to forward
		dot = forward_vec.dot(target_vec)

		rel_loc = get_global_transform().xform_inv(race_path[current])

		#offset = offset_dist(race_path[prev], race_path[current], pos)

		position_on_line = position_line(prev, current, pos, race_path)


	#input
	var gas = false
	var braking = false
	var left = false
	var right = false
	var joy = Vector2(0,0)

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

	# virtual joystick
	if mouse_steer:
		joy = get_node("Joystick/Control").val




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
	process_car_physics(delta, gas, braking, left, right, joy)

	get_node("driver_new/Armature/Spatial").set_rotation(Vector3(get_steering()*2,0,0))
	#get_node("proc_mesh/Spatial/steering").set_rotation(Vector3(get_steering()*2, 0, 0))

	#reset
	if (Input.is_action_pressed("steer_reset")):
		reset_car()

	# racing ctd
	# track the path points
	if race and race_path.size() > 0:
		#if we passed the point, don't backtrack
		if (dot < 0 and rel_loc.distance_to(Vector3(0,0,0)) > 3 and rel_loc.distance_to(Vector3(0,0,0)) < 30):
			#print(get_parent().get_name() + " getting next point after " + str(current) + " because passed over " + str(dot))

			##do we have a next point?
			if (race_path.size() > current+1):
				prev = current
				current = current + 1
			#else:
				#print("We're at the end")
			#	stop = true

		if (rel_loc.distance_to(Vector3(0,0,0)) < 2):

			##do we have a next point?
			if (race_path.size() > current+1):
				#print("AI " + get_parent().get_name() + " gets a next point")
				prev = current
				current = current + 1


# UI stuff doesn't have to be in physics_process
func _process(delta):
	#fps display
	hud.update_fps()

	#speedometer
	speed_int = round(speed)
	speed_kph = round(speed*3.6)
	speed_text = String(speed_int) + " m/s " + String(speed_kph) + " kph"
	# make speed reading red if above speed limit
	if speed > 15:
		hud.update_speed(speed_text, Color(1,0,0))
	else:
		hud.update_speed(speed_text, Color(0,1,1)) #cyan


	hud.update_wheel_angle(get_steering(), 1) #absolute maximum steer limit
	hud.update_angle_limiter(STEER_LIMIT)

	# in-game time
	var text = " "
	if (World_node != null):
		text = String(World_node.hour) + " : " + String(round(World_node.minute))

	hud.update_clock(text)

	#increment distance counter
	distance = distance + get_translation().distance_to(last_pos)
	# same for performance testing
	if count:
		perf_distance = perf_distance + get_translation().distance_to(last_pos)
	last_pos = get_translation()

	distance_int = round(distance)
	#update distance HUD
	hud.update_distance("Distance: " + String(distance_int) + " m")

	var disp = get_compass_heading()
	hud.update_compass(str(disp))

	#var cam_minimap = minimap.get_node("Viewport/minimap").cam2d
	#var cam_rot = (cam_minimap.arr_rot)

	# detect what we're driving on
	var hit = get_node("RayCast").get_collider_hit()
	var disp_name = ""
	if hit != null:
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
						
	# clear text if we passed the newly reached intersection				
	if not reached_changed:
		hud.update_nav_label("")

	hud.update_road(str(disp_name) if hit != null else "")

	#hud.update_debug("Player vel: x: " + str(get_linear_velocity().x) + "y: " + str(get_linear_velocity().z))
	#hud.update_debug("Player: " + str(get_rotation_degrees()) + '\n' + " Arrow : " + str(cam_rot))

	hud.update_health(health)

	hud.update_battery(battery)
	
		

	# shaders stuff
#	#print("Light color" + str(World_node.light_color))
#	if "light_color" in World_node and World_node.light_color != null:
#		var color = Vector3(World_node.light_color.r, World_node.light_color.g, World_node.light_color.b)
#	#print("Color input: " + str(color))
#		get_node("skysphere/Skysphere").get_material_override().set_shader_param("light", color) #Color(World_node.light_color.r, World_node.light_color.g, World_node.light_color.b))
#	#print("Shader color: " + str(get_node("skysphere/Skysphere").get_material_override().get_shader_param("light")))

	# motion blur
	if speed > 28: #100 kphs
		enable_motion_blur(true)
	else:
		enable_motion_blur(false)

func enable_motion_blur(on):
	get_node("cambase/Camera/motion_blur").switch_motion_blur(on)
	# blur trick
	#World_node.env.set_dof_blur_far_enabled(on)
	#World_node.env.set_dof_blur_near_enabled(on)

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

			# hud changes
			hud.toggle_cam(false)
			hud.speed_cockpit()

			# enable rear view mirror
			$"cambase/Viewport/CameraCockpitBack".make_current()
			$"cambase/Viewport".set_update_mode(Viewport.UPDATE_ALWAYS)
			$"cambase/MirrorMesh".set_visible(true)
		else:
			chase_cam.make_current()

			# hud changes
			hud.toggle_cam(true)
			hud.speed_chase()

			# disable rear view mirror
			$"cambase/MirrorMesh".set_visible(false)
			$"cambase/Viewport/CameraCockpitBack".clear_current()
			$"cambase/Viewport".set_update_mode(Viewport.UPDATE_DISABLED)



	if (Input.is_action_pressed("camera_debug")):
		var chase_cam = get_node("cambase/Camera")
		if debug_cam.is_current():
			chase_cam.make_current()
			# hud changes
			hud.toggle_cam(true)
			hud.speed_chase()
			# show tunnels
			var roads = get_tree().get_nodes_in_group("roads")
			for r in roads:
				if 'tunnel' in r and r.tunnel:
					r.show_tunnel()
		else:
			debug_cam.make_current()
			# make tunnels transparent
			var roads = get_tree().get_nodes_in_group("roads")
			for r in roads:
				if 'tunnel' in r and r.tunnel:
					r.debug_tunnel()

#		var cam = get_node("cambase/Camera")
#		if (cam !=null):
#			if (not cam.debug):
#				cam.set_debug(true)
#			else:
#				cam.set_debug(false)


	if (Input.is_action_pressed("look_back")):
		print("Look back!")
		var cam = get_node("cambase/Camera")
		if (cam != null):
			if (not cam.debug):
				if not cam.look_back:
					cam.look_back = true
				else:
					cam.look_back = false

	if (Input.is_action_pressed("perf_debug")):
		print("Performance testing started!")
		count = true
		timer = 0.0
		#reset distance
		perf_distance = 0

	if (Input.is_action_pressed("map")):
		if get_node("Map").is_visible():
			get_node("Map").hide()
		else:
			#print("Show map!")
			get_node("Map").show()
			# force redraw minimap track if any
			get_node("Map").redraw_nav()


# -------------------------------------
func _on_BODY_body_entered(body):
	var obj = body.get_parent().get_parent()
	if body.get_parent().get_name() == "Ground":
		obj = body.get_parent()

	#print("Collided with " + str(obj.get_name()))
	#print("Collided with body at " + str(obj.get_global_transform().origin))

	if not get_parent().is_in_group("bike"):
		if speed > 5:
			print("Speed at collision: " + str(round(speed*3.6)) + "km/h, deducting: " + str(round(speed)))
			# deduct health
			health -= round(speed)
			# deform
			if not get_parent().is_in_group("bike"):
				var local = get_global_transform().xform_inv((obj.get_global_transform().origin))
				$"car_mesh".hit_deform(local)

	if health <= 0:
		# game over!
		var over = game_over.instance()
		add_child(over)

	#print("Health" + str(health))
#	pass

func create_race_path(path):
	print("Creating race path")
	if (path != null and path.size() > 0):
		#print("We have a race path to follow")
		for index in range(path.size()):
			race_path.push_back(path[index])

	#emit_signal("race_path_gotten")
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

# -----------------------------------
func swap_to_bike():
	# get positions
	var p_pos = get_parent().get_translation() #.get_global_transform().origin
	#print("Parent position before swap: " + str(p_pos))
	var pos = get_translation()
	#print("Body pos before swap: " + str(pos))
	
	get_parent().queue_free()
	#var bike_scene = load("res://car/bike_base.tscn")
	var bike = bike_scene.instance()
	bike.set_name("bike")
	# place the bike where the car was
	#bike.get_parent().global_transform.origin = p_pos
	bike.set_translation(p_pos)
	bike.get_node("BODY").set_translation(pos)
	
	get_parent().get_parent().add_child(bike)
	#print("Dummy")
	return bike.get_node("BODY")

func swap_to_car():
	# get positions
	var p_pos = get_parent().get_translation() #.get_global_transform().origin
	#print("Parent position before swap: " + str(p_pos))
	var pos = get_translation()
	#print("Body pos before swap: " + str(pos))
	
	get_parent().queue_free()
	#var car_scene = load("res://car/car_base.tscn")
	var car = car_scene.instance()
	car.set_name("car")
	# place the car where the bike was
	#car.get_parent().global_transform.origin = p_pos
	car.set_translation(p_pos)
	car.get_node("BODY").set_translation(pos)
	
	get_parent().get_parent().add_child(car)
	#print("Dummy")
	return car.get_node("BODY")

# -------------------------------------------
# performance
# a = 2s/t^2
func accel_from_data(t,dist):
	var t2 = pow(t,2)

#	print("T : " + str(t2) + " d: " + str(2*dist))

	# test
	#print("T: " + str(pow(12,2)) + "d: " + str(2*201) + " = " + str((2*201)/pow(12,2)))

	return 2*dist / t2

# a = delta v/ t
func accel_from_time(t):
	return 28 / t

# t = delta v/ a
func time_from_accel(a):
	var vel_change = 28 # in m/s, and the start vel is 0
	# comes out to 10 for 2.79

	return vel_change / a

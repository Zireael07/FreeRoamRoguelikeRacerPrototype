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
var turn

var last_pos
var distance = 0
var distance_int = 0

# setup stuff
var elapsed_secs = 0
var start_secs = 2
var emitted = false

#signal load_ended

var chase_cam
var cockpit_cam = null
var debug_cam
# these are for cockpit cam
var cam_speed = 1
var cockpit_cam_target_angle = 0
var cockpit_cam_angle = 0
var cockpit_cam_max_angle = 5
var peek

# racing
var race
var prev = 0
var current = 0
var lap = 0
var dot = 0
var rel_loc = Vector3()
var race_path = PackedVector3Array()
var finished = false

var money = 0

# player navigation
var reached_inter
var reached_changed = false
var show_nav_tip = false

var hit = null
var count = 0
var was_tunnel = false # for particles
var was_dirt = false
var was_fast = false

var skidmark = null

# vehicle switching
var car_scene = null
var bike_scene = null

func _ready():
	# need to do it explicitly in Godot 4 for some reason
	super._ready()
	
	# preload doesn't work since we're loading from a script that both scenes use
	car_scene = load("res://car/kinematics/kinematic_car_base.tscn")
	bike_scene = load("res://car/kinematics/kinematic_bike.tscn")
	
	# our custom signal
	EventBus.connect(&"load_ended", self.on_load_ended)

	World_node = get_parent().get_parent().get_node("scene")
	cockpit_cam = $"cambase/CameraCockpit"
	debug_cam = $"cambase/CameraDebug"
	chase_cam = get_node(^"cambase/Camera3D")
	tail_mat = taillights.get_mesh().surface_get_material(0)

	##GUI
	var h = preload("res://hud/hud.tscn")
	hud = h.instantiate()
	add_child(hud)

	var v = preload("res://hud/virtual_joystick.tscn")
	vjoy = v.instantiate()
	vjoy.set_name("Joystick")
	# we default to mouse steering off
	vjoy.hide()
	add_child(vjoy)


	# get map seed
	map = get_parent().get_parent().get_node("map")
	if map != null:
		hud.update_seed(map.get_node(^"triangulate/poisson").seed3)

	var m = preload("res://hud/Viewport.tscn")
	minimap = m.instantiate()
	minimap.set_name("Viewport_root")
	add_child(minimap)
	minimap.set_name("Viewport_root")

	m = preload("res://hud/MapView.tscn")
	map_big = m.instantiate()
	map_big.set_name("Map")
	# share the world with the minimap
	map_big.get_node(^"SubViewport").world_2d = get_node(^"Viewport_root/SubViewport").world_2d
	add_child(map_big)
	map_big.hide()

	var msg = preload("res://hud/message_panel.tscn")
	panel = msg.instantiate()
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
	var pau = pause.instantiate()
	add_child(pau)

	game_over = preload("res://hud/game_over.tscn")

	# distance
	last_pos = get_position()

	skidmark = preload("res://objects/skid_mark.tscn")
	
	# smoke color
	var snow_mat = load("res://assets/snow_smoke_mat.tres")
	var smoke_mat = load("res://assets/Smoke_mat.tres")
	if get_parent().get_parent().get_node(^"Ground").snow:
		get_node(^"Smoke").material_override = snow_mat
		get_node(^"Smoke2").material_override = snow_mat
	else:
		get_node(^"Smoke").material_override = smoke_mat
		get_node(^"Smoke2").material_override = smoke_mat

func spawn_message():
	var msg = preload("res://hud/message_panel.tscn")
	panel = msg.instantiate()
	panel.set_name("Messages")
	add_child(panel)
	return panel

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
	chase_cam.make_current()
	# disable rear view mirror
	$"cambase/MirrorMesh".set_visible(false)
	$"cambase/SubViewport/CameraCockpitBack".clear_current()
	$"cambase/SubViewport".set_update_mode(SubViewport.UPDATE_DISABLED)

	# temporarily disable
	#get_node(^"driver_new").setup_ik()

	# optimize label/nameplate rendering
	get_node(^"..").freeze_viewports()

# ----------------------------------------------------------------
# kinematic driving
func get_input():
	turn = Input.get_action_strength("steer_left")
	turn -= Input.get_action_strength("steer_right")
	steer_target = turn * deg2rad(steering_limit)
	#var steer_angle = get_steering_angle(steer_target)
	$tmpParent/Spatial_FL.rotation.y = steer_angle*2
	$tmpParent/Spatial_FR.rotation.y = steer_angle*2
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("accelerate"):
		acceleration = -transform.basis.z * engine_power
		#cancel braking visual
		if tail_mat != null:
			tail_mat.set_albedo(Color(0.62,0.62,0.62))
			tail_mat.set_feature(StandardMaterial3D.FEATURE_EMISSION, false)
	if Input.is_action_pressed("brake"):
		acceleration = -transform.basis.z * braking_power
		#visual effect
		if tail_mat != null:
			tail_mat.set_albedo(Color(1,1,1))
			tail_mat.set_feature(StandardMaterial3D.FEATURE_EMISSION, true)

	# tilt cockpit cam
	if not cockpit_cam.is_current():
		return
	# left
	if turn > 0 and cockpit_cam_target_angle > -11 and cockpit_cam_target_angle < 30:
		#print("Turning left, peeking left, ", cockpit_cam_target_angle)
		cockpit_cam_target_angle += 1
	# right
	if turn < 0 and cockpit_cam_target_angle < 11 and cockpit_cam_target_angle > -40:
		#print("Turning right, peeking right, ", cockpit_cam_target_angle)
		cockpit_cam_target_angle -= 1
		

# --------------------------------------------------
func damage_on_hit():
	if not get_parent().is_in_group("bike"):
		if speed > 5:
			print("Speed at collision: " + str(round(speed*3.6)) + "km/h, deducting: " + str(round(speed)))
			# deduct health
			health -= round(speed)

	if health <= 0:
		# game over!
		var over = game_over.instantiate()
		add_child(over)


func _physics_process(delta):
	# for some reason, needed in Godot 4
	super._physics_process(delta)
	
	
	# were we peeking last tick?
	var old_peek = peek
	
	# emit a signal when we're all set up
	elapsed_secs += delta
	if (elapsed_secs > start_secs and not emitted):
		EventBus.emit_signal("load_ended")
		emitted = true
		
	# racing
	if race and race_path.size() > 0:
		var forward_global = get_global_transform() * (Vector3(0, 0, 2))
		var forward_vec = forward_global-get_global_transform().origin

		var pos = get_global_transform().origin
		#B-A = from A to B
		var target_vec = race_path[current] - pos
		# forward vec goes from origin to forward
		dot = forward_vec.dot(target_vec)

		rel_loc = race_path[current] * get_global_transform()

		#offset = offset_dist(race_path[prev], race_path[current], pos)

		position_on_line = position_line(prev, current, pos, race_path)
		
	# cockpit camera
	if Input.is_action_pressed("peek_left"):
		if not peek: 
			peek = true
		else:
			peek = false
		#print("Peek left")
		if cockpit_cam.is_current():
			# cancel the opposing peek
			if cockpit_cam_target_angle < -35:
				print("Should cancel peek right")
				peek = false
				cockpit_cam_angle = 0
			else:
				cockpit_cam_target_angle = 30

	if Input.is_action_pressed("peek_right"):
		if not peek:
			peek = true
		else:
			peek = false
		#print("Peek right")
		if cockpit_cam.is_current():
			# cancel the opposing peek
			if cockpit_cam_target_angle > 25:
				print("Should cancel peek left")
				peek = false
				cockpit_cam_angle = 0
			else:
				cockpit_cam_target_angle = -40
			

	# reset cam
	if turn == 0 and not peek:
		# if we were peeking last frame but are not now
		if old_peek and cockpit_cam.is_current():
			cockpit_cam_angle = 0
			#print("Old peek is: " + str(old_peek))

		# reset cam
		if cockpit_cam.is_current():
			cockpit_cam_target_angle = 0

	# vary cam speed

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
			#print("Setting to target angle: " + str(cockpit_cam_target_angle))
			cockpit_cam_angle = cockpit_cam_target_angle
	# right
	if (cockpit_cam_target_angle > cockpit_cam_angle):
		cockpit_cam_angle += cam_speed*delta
		#print("Cockpit cam angle: ", cockpit_cam_angle)
		# bugs
		#if (cockpit_cam.target_angle < cockpit_cam.max_angle):
		#	print("Setting to target angle: " + str(cockpit_cam.target_angle))
		#	cockpit_cam.angle = cockpit_cam.target_angle

	cockpit_cam.set_rotation(Vector3(deg2rad(180),deg2rad(cockpit_cam_angle), deg2rad(180)))

	# did we run into ...
	if get_slide_collision_count():
		var collision = get_slide_collision(0)
		# a cardboard box?
		if collision.get_collider() is RigidDynamicBody3D:
			var nam = collision.get_collider().get_name()
			#print(nam)
			# push on it
			var cr_imp = -get_global_transform().basis.z.normalized() * 4
			collision.get_collider().apply_impulse(Vector3(0,-2,0), Vector3(cr_imp.x, 0, cr_imp.z))
		# did we hit the train?
		if collision.get_collider() is AnimatableBody3D:
			# is it moving?
			if collision.get_collider().get_parent().get_node("AnimationPlayer").is_playing():
				# game over
				health = 0
	
		var nam = collision.get_collider().get_parent().get_name()
		#print(nam)
		# ignore ground or road "collisions"
		if "Ground" in nam or "Road" in nam:
			pass
		else:	
			damage_on_hit()
	
func after_move():
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
			else:
				if lap > 0:
					current = 0
					lap = lap+1
			#else:
				#print("We're at the end")
			#	stop = true

		if (rel_loc.distance_to(Vector3(0,0,0)) < 2):

			##do we have a next point?
			if (race_path.size() > current+1):
				#print("AI " + get_parent().get_name() + " gets a next point")
				prev = current
				current = current + 1
			else:
				if lap > 0:
					current = 0
					lap = lap+1

func reset_car():
	print("Reset!")
	#var tr = get_parent().get_translation()
	#get_parent().set_translation(Vector3(tr.x, 0.5, tr.z))
	#global_translate(Vector3(0, 0.5,0))
	translate_object_local(Vector3(0,0.1,0))
	# solution from https://godotengine.org/qa/56193/how-to-manually-set-the-position-of-a-kinematicbody2d
	set_velocity(Vector3(0,gravity/10,0))
	move_and_slide() #

	#gravity = 20

# UI stuff doesn't have to be in physics_process
func _process(delta):
	#fps display
	hud.update_fps()
	
	#test stuff
	if has_node("occupancy_map"):
		var data = []
		for p in get_node("occupancy_map").memory:
			var d = [to_local(p[0]), get_node("occupancy_map").pos3d_to_grid(to_local(p[0])), get_node("occupancy_map").get_raycast_id_for_pos(p[0])]
			data.append(d)
		hud.update_debug_stuff(data, get_node("occupancy_map").rays, \
		get_node("occupancy_map").danger, get_node("occupancy_map").interest, 
		get_node("occupancy_map").chosen_dir)

	#speedometer
	speed_int = round(speed)
	speed_kph = round(speed*3.6)
	#speed_text = String(speed_int) + " m/s " + String(speed_kph) + " kph"
	speed_text = var2str(int(speed_kph))
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
		text = var2str(int(World_node.hour)) + " : " + var2str(int(round(World_node.minute)))

	hud.update_clock(text)

	#increment distance counter
	distance = distance + get_position().distance_to(last_pos)

	last_pos = get_position()

	distance_int = round(distance)
	#update distance HUD
	hud.update_distance("Distance: " + var2str(distance_int) + " m")

	var disp = get_compass_heading()
	hud.update_compass(str(disp))

	var data = driving_on_road()
						
	# clear text if we passed the newly reached intersection				
	if not reached_changed and not show_nav_tip:
		hud.update_nav_label("")

	hud.update_road(str(data[1]) if data[0] != null else "")

	hud.update_health(health)

	hud.update_battery(battery)


	# stop weather particles when in tunnel
	if hit != null and 'tunnel' in hit.get_parent().get_parent() and hit.get_parent().get_parent().tunnel:
		was_tunnel = true
		get_node(^"RainParticles").set_emitting(false)
		get_node(^"RainParticles2").set_emitting(false)
	else:
		if was_tunnel and World_node.weather > 1: # rain or snow
			was_tunnel = false
			get_node(^"RainParticles").set_emitting(true)
			get_node(^"RainParticles2").set_emitting(true)

	# skid marks
	if speed < 5 and map != null:
		var pos = get_node(^"cambase/Camera3D").get_global_transform().origin
		var mark = skidmark.instantiate()
		var wh_pos = get_node(^"tmpParent/Spatial_RL")
		var mark_pos = wh_pos.get_global_transform().origin - Vector3(0,0.3, 0) # tiny offset to make marks show on roads
		var lpos = map.to_local(mark_pos)
		mark.set_position(lpos)
		# place all the skidmarks under a common parent
		var gfx = null
		if not map.has_node("gfx"):
			gfx = Node3D.new()
			gfx.set_name("gfx")
			map.add_child(gfx)
		else:
			gfx = map.get_node(^"gfx")
			
		gfx.add_child(mark)
		mark.look_at(pos, Vector3(0,1,0))
		# flip around because... +Z vs -Z...
		#mark.rotate_y(deg2rad(180))
		#mark.rotate_x(deg2rad(-90))

		mark = skidmark.instantiate()
		wh_pos = get_node(^"tmpParent/Spatial_RR")
		mark_pos = wh_pos.get_global_transform().origin - Vector3(0,0.3, 0) # tiny offset to make marks show on roads
		lpos = map.to_local(mark_pos)
		mark.set_position(lpos)
		# we should already have the common parent, see above
		gfx.add_child(mark)
		mark.look_at(pos, Vector3(0,1,0))

#doesn't interact with physics
func _input(event):
	if (Input.is_action_pressed("headlights_toggle")):
		if (get_node(^"SpotLight3D").is_visible()):
			setHeadlights(false)
		else:
			setHeadlights(true)
	
	# switch cameras
	if (Input.is_action_pressed("camera")):
		var chase_cam = get_node(^"cambase/Camera3D")
		var cockpit_cam = get_node(^"cambase/CameraCockpit")
		if chase_cam.is_current():
			cockpit_cam.make_current()

			# hud changes
			hud.toggle_cam(false)
			hud.speed_cockpit()

			# enable rear view mirror
			$"cambase/SubViewport/CameraCockpitBack".make_current()
			$"cambase/SubViewport".set_update_mode(SubViewport.UPDATE_ALWAYS)
			$"cambase/MirrorMesh".set_visible(true)
		else:
			chase_cam.make_current()

			# hud changes
			hud.toggle_cam(true)
			hud.speed_chase()

			# disable rear view mirror
			$"cambase/MirrorMesh".set_visible(false)
			$"cambase/SubViewport/CameraCockpitBack".clear_current()
			$"cambase/SubViewport".set_update_mode(SubViewport.UPDATE_DISABLED)
	
			
	if (Input.is_action_pressed("camera_debug")):
		var chase_cam = get_node(^"cambase/Camera3D")
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

	if (Input.is_action_pressed("map")):
		if get_node(^"Map").is_visible():
			get_node(^"Map").hide()
		else:
			#print("Show map!")
			get_node(^"Map").show()
			# force redraw minimap track if any
			get_node(^"Map").redraw_nav()
			
		
	#reset
	if (Input.is_action_pressed("steer_reset")):
		reset_car()	

# -----------------------------------------

func driving_on_road():
	# detect what we're driving on
	var ray_hit = get_node("RayCast3D").get_collider()
	var disp_name = ""

	# don't lose track of area assigned hits
	if hit and 'length' in hit:
		pass
	else:
		hit = ray_hit

	if hit != null:
		# particles
		count = 0
		was_dirt = false
		get_node(^"Smoke").set_emitting(false)
		get_node(^"Smoke2").set_emitting(false)
		
		#var road_ = hit.get_parent().get_name().find("Road_")
		var road = String(hit.get_node(^"../../..").get_name()).find("Road")
		#var road = hit.get_node(^"../../../../").get_name().find("Road")
		# straight
		if 'length' in hit:
		#if road_ != -1:
			disp_name = hit.get_node(^"../../").get_name()
			reached_changed = false
		# curve
		elif road != -1:
			disp_name = hit.get_node(^"../../../../").get_name()
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
						minimap.get_node(^"SubViewport/minimap").remove_arrow(r)
			
			# if we have a player navigation path
			if map_big and map_big.int_path.size() > 0:
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
						
		#mark_road_discovered(disp_name)
	# else we're on a dirt ground
	else:
		if not was_dirt:
			count += 1
			if count > 2:
				was_dirt = true
				get_node(^"Smoke").set_emitting(true)
				get_node(^"Smoke2").set_emitting(true)

	return [hit, disp_name]

func mark_road_discovered(disp_name):
	if "intersection" in disp_name:
		return
	
	var root = get_node(^"/root/Node3D")
	# paranoia
	if root == null:
		return
	# or !"discovered_roads" in root
	
	if not root.discovered_roads.has(disp_name):
		root.discovered_roads[disp_name] = true
		print("Marked " + disp_name + " as discovered")

# ---------------------------------

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
	var forward_global = get_global_transform() * (Vector3(0, 0, -2))
	var forward_vec = forward_global-get_global_transform().origin
	#var basis_vec = player.get_global_transform().basis.z
	
	# looks like this is always positive?!
	#var player_rot = forward_vec.angle_to(Vector3(0,0,1))
	# returns radians
	#return player_rot
	if not has_node("/root/Node3D/marker_North"):
		return 0
	
	var North = get_node("/root/Node3D/marker_North")
	#if North == null:
	#	return 0
	var rel_loc = to_local(North.get_global_transform().origin)  #(North.get_global_transform() * get_global_transform().origin)
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
	var intersections = get_node(^"Viewport_root/SubViewport/minimap").intersections
	var pos_gl = intersections[id]
	#print("Global position ", pos_gl)
	var rel_pos = pos_gl * get_global_transform()
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
	var pos = get_position()
	#print("Body pos before swap: " + str(pos))
	
	get_parent().queue_free()
	var bike = bike_scene.instantiate()
	bike.set_name("bike")
	# place the bike where the car was
	#bike.get_parent().global_transform.origin = p_pos
	bike.set_translation(p_pos)
	bike.get_node(^"BODY").set_translation(pos)
	
	get_parent().get_parent().add_child(bike)
	#print("Dummy")
	return bike.get_node(^"BODY")

func swap_to_car():
	# get positions
	var p_pos = get_parent().get_translation() #.get_global_transform().origin
	#print("Parent position before swap: " + str(p_pos))
	var pos = get_position()
	#print("Body pos before swap: " + str(pos))
	
	get_parent().queue_free()

	var car = car_scene.instantiate()
	car.set_name("car")
	# place the car where the bike was
	#car.get_parent().global_transform.origin = p_pos
	car.set_translation(p_pos)
	car.get_node(^"BODY").set_translation(pos)
	
	get_parent().get_parent().add_child(car)
	#print("Dummy")
	return car.get_node(^"BODY")


# -------------------------
func delay_new_events():
	var mmap = get_node(^"Viewport_root/SubViewport/minimap")
	mmap.add_event_markers()


func reset_events():
	var mmap = get_node(^"Viewport_root/SubViewport/minimap")
	var markers = get_tree().get_nodes_in_group("marker")
	# remove previous day's events
	for e in markers:
		e.queue_free()
		# remove minimap markers
		mmap.remove_marker(e.get_global_transform().origin)

	#TODO: add a message or a visual effect on the map!

	# new events
	var marker_data = map.get_node(^"nav").spawn_markers(map.samples, map.real_edges)
	#map.get_node(^"nav").setup_markers(marker_data)
	
	# we have to wait here because otherwise it shows markers for old events too
	# wait
	var t = Timer.new()
	t.set_wait_time(3)
	t.set_one_shot(true)
	self.add_child(t)
	t.start()
	await t.timeout
	# stuff after delay
	map.get_node(^"nav").setup_markers(marker_data)
	delay_new_events()
	t.queue_free()

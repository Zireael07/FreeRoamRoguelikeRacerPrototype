extends Node3D

# class member variables go here, for example:
var player
var player_script
var time
var count
#start/finish
var finish = false
var start

@export var target = Vector3()
var raceline = PackedVector3Array() #is a Vector3 array because of the positioning system
var ai_data = []

# race
var racer
var cars = []

var done = false

var grid 

func _ready():
	player_script = load("res://car/kinematics/kinematic_vehicle_player.gd")
	count = false
	
	racer = preload("res://car/kinematics/kinematic_car_AI_racer.tscn")
	grid = preload("res://objects/grid spot marker.tscn")
	
	set_process(true)
	# Called every time the node is added to the scene.
	# Initialization here

func set_finish(val):
	finish = val

func _on_Area_body_enter( body ):
	if body is CharacterBody3D:
		if body is player_script and not body.get_parent().is_in_group("bike"):
			print("Area3D entered by the player")
			player = body
			
			if finish:
				if player.finished:
					return # ignore re-crossing if finished
				
				#print("Reached finish marker")
				
				# flag player as finished
				player.finished = true
				
				start.count = false
				
				# has to be here because doing it in _on_results_close reports wrong positions
				var player_result = start.get_player_position()
				print("Player finished: ", player_result)
				# prize
				if player_result == 1:
					player.money += 200
				if player_result == 2:
					player.money += 150
				player.hud.update_money(player.money)
				
				
				var msg = body.spawn_message()
				#msg.set_initial(false)
				
				var results = player.get_node(^"root").get_node(^"Label timer").get_text()
				msg.set_text("FINISH TEST RACE!" + "\n" + results)
				#msg.get_node(^"OK_button").connect(&"pressed", self._on_results_close)
				msg.get_node(^"Button").connect(&"pressed", self._on_results_close)
				print("Connected: ", msg.get_node(^"Button").is_connected("pressed", Callable(self, "_on_results_close")))
				msg.enable_ok(false)
				msg.show()
				
				# clear & hide timing
				player.get_node(^"root").get_node(^"Label timer").set_text("")
				player.get_node(^"root").get_node(^"Label timer").hide()
				
				# remove raceline from map
				var track_map = player.get_node(^"Viewport_root/SubViewport/minimap/Container/Node2D2/Control_pos/track")
				track_map.points = []
				# force redraw
				track_map.update()
				
				# remove target flag from minimap
				var minimap = player.get_node(^"Viewport_root/SubViewport/minimap")
				minimap.remove_marker(self.get_global_transform().origin)
				
				#remove finish
				#queue_free()
			else:
				var msg = body.spawn_message()
				#msg.set_initial(false)
				msg.set_text("TEST RACE! " + "\n" + "Race others to the finish marker")

				msg.get_node(^"OK_button").connect(&"pressed", self._on_ok_click)
				if raceline.size() > 0:
					print("Got raceline")
					msg.enable_ok(true)
					
					# show raceline on minimap
					var track_map = player.get_node(^"Viewport_root/SubViewport/minimap/Container/Node2D2/Control_pos/track")
					track_map.points = track_map.vec3s_convert(raceline)
					# force redraw
					track_map.update()
					
					# prompt to turn around if needed
					var rel_pos = raceline[1] * player.get_global_transform()
					#print("Race rel pos: ", rel_pos)
					#2D angle to target (local coords)
					var angle = atan2(rel_pos.x, rel_pos.z)
					var forward_global = player.get_global_transform() * (Vector3(0, 0, -2))
					var forward_vec = forward_global-player.get_global_transform().origin
					var tg_dir = raceline[1] - player.get_global_transform().origin
					var dot = forward_vec.dot(tg_dir)
					
					player.show_nav_tip = true

					if dot < 0:
						player.hud.update_nav_label("TURN AROUND FOR RACE")
					elif abs(angle) > 0.75 and rel_pos.x > 3:
						player.hud.update_nav_label("TURN LEFT FOR RACE")
					elif abs(angle) > 0.75 and rel_pos.x < 3:
						player.hud.update_nav_label("TURN RIGHT FOR RACE")
					
				else:
					print("No raceline, abort")
					msg.enable_ok(false)
				
				msg.show()
		else:
			#print("Area3D entered by AI car")
			if finish:
				#print("Finish area entered by AI")
				if body.get_parent().is_in_group("race_AI"):
					# flag AI as finished
					body.finished = true
		#	print("Area3D entered by a car " + body.get_parent().get_name())
	#else:
	#	print("Area3D entered by something else")

func _on_results_close():
	#remove finish
	queue_free()
	# flag race as over
	player.race = null
	player.finished = true
	
	# restore particles
	for n in get_tree().get_nodes_in_group("marker"):
		n.get_node(^"GPUParticles3D").emitting = true
	
	# reset car list to empty (in case we want to do this race again)
	cars = []
	
	print("[RACE] RESULTS CLOSED")

func _on_ok_click():
	cars = []
	# clear turn tip
	player.show_nav_tip = false
	count = true
	time = 0.0
	spawn_finish(self)
	#print("Our pos: " + str(get_global_transform().origin))
	#print("Raceline end: " + str(raceline[0]))
	
	# find someplace we can attach cars to
	var cars_root = player.get_parent().get_parent().get_node(^"Racers")
	# should place the root on top of us
	cars_root.set_global_transform(get_global_transform())
	var local = cars_root.to_local(get_global_transform().origin)
	
	# fixes local placement relative to race track
	cars_root.look_at(raceline[0], Vector3(0,1,0))
	#cars_root.rotate_y(deg2rad(180))
	
	var pos = cars_root.to_local(raceline[0])
	#print("Pos: " + str(pos))
	spawn_racer(pos)
	pos = pos + Vector3(0,0,8)
	spawn_racer(pos)
	
	# remove the particles from all other markers
	for n in get_tree().get_nodes_in_group("marker"):
		if 'finish' in n and n.finish:
			continue # skip our finish
		n.get_node(^"GPUParticles3D").emitting = false
	
	print("[RACE] Clicked ok!")
	
# race positioning system
# the AI sends us a signal when it has the path
func _on_path_gotten(ai):
	print("[RACE] On path gotten")
	#var ai = car.get_node(^"BODY")
	var raceline = ai.path
	#print("Race line is " + str(raceline))
	player.race = self
	player.create_race_path(raceline)
	#print("[RACE] Player was given the path")

	# send the track to the map
	var track_map = player.get_node(^"Viewport_root/SubViewport/minimap/Container/Node2D2/Control_pos/track")
	track_map.points = track_map.vec3s_convert(raceline)
	# force redraw
	track_map.update()

# ---------------------------------------
func get_distance_along_raceline(line_pos, path):
	#print("Position along raceline: " + str(line_pos[0]))
	var distance = line_pos[0].distance_to(path[line_pos[1]])
	if line_pos[1] > 0 and line_pos[1] < 2:
		var segment_distance = path[0].distance_to(path[line_pos[1]])
		distance = distance + segment_distance
	
	return distance

func get_distance_from_prev(line_pos, path):
	if line_pos != null:
		var distance = line_pos[0].distance_to(path[line_pos[1]])
		return distance
	else:
		return null

# --------------------------
# sorting
# helper
func pos_on_raceline(car):
	var car_pos = null
	if "position_on_line" in car:
		if car.position_on_line != null:
			car_pos = car.position_on_line
	return car_pos
	
func positions_compare(a, b):
	# check for crossing the finish line first
	if a.finished and not b.finished:
		return true
	elif b.finished and not a.finished:
		return false
	# check points on raceline
	else:
		if a.current > b.current:
			#print("AI's current higher")
			return true
		elif a.current == b.current:
			#print("Same current, comparing distances")
			var a_dist = get_distance_from_prev(pos_on_raceline(a), raceline)
			#print("AI dist: " + str(AI_dist))
			var b_dist = get_distance_from_prev(pos_on_raceline(b), raceline)
			#print("Player dist: " + str(player_dist))

			if a_dist != null and b_dist != null:
				if a_dist > b_dist:
					#print("AI dist higher")
					return true
				else:
					#print("player dist higher")
					return false
		else:
			#print("player current higher")
			return false

	
func get_positions_simple():
	if not done: return []
	else:
		var positions = []
		
		# to compare needs the physics body, not ai above it
		var to_compare = [] #cars.duplicate()
		for car in cars:
			var ai = car.get_node(^"BODY")
			to_compare.append(ai)
			
		to_compare.append(player)

		# sort (NOTE: the "Object" can be self!)
		to_compare.sort_custom(Callable(self, &"positions_compare"))
		
		#print(to_compare)
		
		for body in to_compare:
			positions.append(body.get_parent().romaji)
		
#			var dist = player.get_global_transform().origin.distance_to(car.get_node(^"BODY").get_global_transform().origin)
			
#			positions.push_back(car.romaji)
#			positions.push_back(player.get_parent().romaji + ' +' + str(int(dist)) + 'm')
		
		#print(str(positions))
		
		return positions

func displayed_positions():
	var string = ""
	var positions = get_positions_simple()
	
	for i in range(positions.size()):
		string = string + "\n" + str(i+1) + " " + str(positions[i])

	return string

func get_player_position():
	var positions = get_positions_simple()
	return positions.find("Ichiro")+1 # Note: will need to be changed when the player can change their name


func _process(delta):
	if count:
		time += delta
		#print("Timer is " + str(time))
		player.get_node(^"root").get_node(^"Label timer").show()
		#print(str(get_positions_simple()))
		player.get_node(^"root").update_timer(str(time) + '\n' + str(displayed_positions()))
		# str(get_positions_simple()))
	#else:
	#	print("Count is off")

func _on_Area_body_exit( body ):
	if body is CharacterBody3D:
		if body is player_script:
			#print("Area3D exited by the player")
			player = body
			if not finish:
				var msg = body.get_node(^"Messages")
				if msg:
					msg.queue_free()
					# remove raceline (preview) from map
					var track_map = player.get_node(^"Viewport_root/SubViewport/minimap/Container/Node2D2/Control_pos/track")
					track_map.points = []
					# force redraw
					track_map.update()
					# hide turn tip
					player.show_nav_tip = false
				
func spawn_finish(start):
	if raceline.size() > 0:
		pass #print("Got raceline")
	else:
		print("No raceline, abort")
		return
		
	print("Should be spawning finish")
	var loc = target
	#var our = preload("res://objects/race_marker.tscn")
	#var finish = our.instantiate()
	var finish = self.duplicate()
	finish.set_name("Finish")
	finish.set_position(Vector3(loc.x, 0.25, loc.z))
	finish.finish = true
	finish.start = start
	
	# make the detection area wide...
	finish.get_node(^"Area3D/CollisionShape3D").shape.set_size(Vector3(4*2, 2, 0.85*2))
	
	#finish.set_val(true)
	
	get_parent().add_child(finish)
	#add to minimap
	var minimap = player.get_node(^"Viewport_root/SubViewport/minimap")
	minimap.add_marker(finish.get_global_transform().origin, minimap.red_flag)
	
	# rotate
	finish.look_at(raceline[raceline.size()-1], Vector3(0,1,0))

# differences to normal marker start here
func spawn_racer(loc):
	print("Offset: " + str(loc))

	var car = racer.instantiate()
	car.set_name("Racer")
	
	# add to list of cars
	cars.append(car)
	
	# find someplace we can attach cars to
	var cars_root = player.get_parent().get_parent().get_node(^"Racers")
	
	# spawn grid marker
	var g = grid.instantiate()
	cars_root.add_child(g)
	g.look_at(cars_root.to_global(loc), Vector3(0,1,0))
	g.set_position(loc)
	
	#print("Translation:" + str((local+loc)))
	car.target = target
	# pass intersection data to AI
	car.race_int_path = [ai_data[0], ai_data[1]]
	car.race_target = ai_data[2]
	car.race = self
	
	car.left = false
	
	cars_root.add_child(car)
	# look at wants global position
	car.get_node(^"BODY").look_at(cars_root.to_global(loc), Vector3(0,1,0))
	#car.rotate_y(deg2rad(180))
	# needs to come AFTER rotations
	car.set_position(loc)
	
	#print("Added the car")
	
	# add a minimap arrow
	var minimap = player.get_node(^"Viewport_root/SubViewport/minimap")
	minimap.add_arrow(car)
	

extends Spatial

# class member variables go here, for example:
var player
var player_script
var time
var count
#start/finish
var finish = false
var start

export var target = Vector3()
var raceline = PoolVector3Array()
var ai_data = []

# race
var racer
var car

var done = false

func _ready():
	player_script = load("res://car/vehicle_player.gd")
	count = false
	
	racer = preload("res://car/car_AI_racer.tscn")
	
	set_process(true)
	# Called every time the node is added to the scene.
	# Initialization here

func set_finish(val):
	finish = val

func _on_Area_body_enter( body ):
	if body is VehicleBody:
		if body is player_script:
			print("Area entered by the player")
			player = body
			
			if finish:
				print("Reached finish marker")
				start.count = false
				
				var msg = body.get_node("Messages")
				#msg.set_initial(false)
				msg.set_text("FINISH TEST RACE!")
				#msg.get_node("OK_button").connect("pressed", self, "_on_ok_click")
				msg.enable_ok(false)
				msg.show()
				
				# clear & hide timing
				player.get_node("root").get_node("Label timer").set_text("")
				player.get_node("root").get_node("Label timer").hide()
				
				# remove raceline from map
				var track_map = player.get_node("Viewport_root/Viewport/minimap/Container/Node2D2/Control_pos/track")
				track_map.points = []
				# force redraw
				track_map.update()
				
				#remove finish
				queue_free()
			else:
				var msg = body.get_node("Messages")
				#msg.set_initial(false)
				msg.set_text("TEST RACE! " + "\n" + "Race one guy to the finish marker")
				# disconnect all others to prevent bugs
				for d in msg.get_node("OK_button").get_signal_connection_list("pressed"):
						print(d["target"])
						msg.get_node("OK_button").disconnect("pressed", d["target"], "_on_ok_click")
				msg.get_node("OK_button").connect("pressed", self, "_on_ok_click")
				msg.enable_ok(true)
				msg.show()
		#else:
		#	print("Area entered by a car " + body.get_parent().get_name())
	#else:
	#	print("Area entered by something else")


func _on_ok_click():
	count = true
	time = 0.0
	spawn_finish(self)
	#print("Our pos: " + str(get_global_transform().origin))
	#print("Raceline end: " + str(raceline[0]))
	var pos = to_local(raceline[0])
	#print("Pos: " + str(pos))
	spawn_racer(pos)
	print("Clicked ok!")
	
# race positioning system
# the AI sends us a signal when it has the path
func _on_path_gotten():
	print("On path gotten")
	var ai = car.get_node("BODY")
	var raceline = ai.path
	#print("Race line is " + str(raceline))
	player.race = self
	player.create_race_path(raceline)

	# send the track to the map
	var track_map = player.get_node("Viewport_root/Viewport/minimap/Container/Node2D2/Control_pos/track")
	track_map.points = track_map.vec3s_convert(raceline)
	# force redraw
	track_map.update()

func get_AI_position_on_raceline():
	if not done: return null
	else:
		var ai = car.get_node("BODY")
		#var raceline = ai.path
		var AI_pos = ai.position_on_line
	
		return AI_pos

func get_player_position_on_raceline():
	if not done: return null
	else:
		var player_pos = null
		if "position_on_line" in player:
			if player.position_on_line != null:
				player_pos = player.position_on_line
		
		return player_pos

func get_positions_on_raceline():
	var AI_pos = get_AI_position_on_raceline()
	var player_pos = get_player_position_on_raceline()
#	if not done: return null
#	else:
#		var ai = car.get_node("BODY")
#		var raceline = ai.path
#		var AI_pos = ai.position_on_line
#		
#		var player_pos = null
#		if "position_on_line" in player:
#			if player.position_on_line != null:
#				player_pos = player.position_on_line
		
	return [AI_pos, player_pos]

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
		
func get_positions():
	if not done: return null
	var ai = car.get_node("BODY")
	var raceline = ai.path
	
	
	var positions = []
	var points = get_positions_on_raceline()
	if points != null:
		for pt in points:
			if pt != null:
				positions.push_back(get_distance_along_raceline(pt, raceline))
		
	return positions
	
func get_positions_simple():
	if not done: return []
	else:
		var positions = []
		var ai = car.get_node("BODY")
	
		var raceline = ai.path
		
		if ai.current > player.current:
			#print("AI's current higher")
			positions.push_back(car.romaji)
			positions.push_back(player.get_parent().romaji)
		elif ai.current == player.current:
			#print("Same current, comparing distances")
			var AI_dist = get_distance_from_prev(get_AI_position_on_raceline(), raceline)
			#print("AI dist: " + str(AI_dist))
			var player_dist = get_distance_from_prev(get_player_position_on_raceline(), raceline)
			#print("Player dist: " + str(player_dist))
			if AI_dist != null and player_dist != null:
				if AI_dist > player_dist:
					#print("AI dist higher")
					positions.push_back(car.romaji)
					positions.push_back(player.get_parent().romaji)
				else:
					#print("player dist higher")
					positions.push_back(player.get_parent().romaji)
					positions.push_back(car.romaji)
		else:
			#print("player current higher")
			positions.push_back(player.get_parent().romaji)
			positions.push_back(car.romaji)
		
		
		#print(str(positions))
		
		return positions

func displayed_positions():
	var string = ""
	var positions = get_positions_simple()
	
	for i in range(positions.size()):
		string = string + "\n" + str(i+1) + " " + str(positions[i])

	return string

func _process(delta):
	if count:
		time += delta
		#print("Timer is " + str(time))
		player.get_node("root").get_node("Label timer").show()
		#print(str(get_positions_simple()))
		player.get_node("root").update_timer(str(time) + '\n' + str(displayed_positions()))
		# str(get_positions_simple()))
	#else:
	#	print("Count is off")

func _on_Area_body_exit( body ):
	if body is VehicleBody:
		if body is player_script:
			print("Area exited by the player")
			player = body
			if not finish:
				var msg = body.get_node("Messages")
				msg.hide()
				
func spawn_finish(start):
	if raceline.size() > 0:
		print("Got raceline")
	else:
		print("No raceline, abort")
		return
		
	print("Should be spawning finish")
	var loc = target
	#var our = preload("res://objects/race_marker.tscn")
	#var finish = our.instance()
	var finish = self.duplicate()
	finish.set_name("Finish")
	finish.set_translation(Vector3(loc.x, 0.25, loc.z))
	finish.finish = true
	finish.start = start
	#finish.set_val(true)
	
	get_parent().add_child(finish)
	#add to minimap
	var minimap = player.get_node("Viewport_root/Viewport/minimap")
	minimap.add_marker(finish.get_global_transform().origin, minimap.red_flag)
	
	# test
	var track_map = player.get_node("Viewport_root/Viewport/minimap/Container/Node2D2/Control_pos/track")
	track_map.points = track_map.vec3s_convert(raceline)
	# force redraw
	track_map.update()

# differences to normal marker start here
func spawn_racer(loc):
	print("Offset: " + str(loc))
	car = racer.instance()
	car.set_name("Racer")
	
	# find the root of the scene
	var cars = player.get_parent().get_parent()
	var local = cars.to_local(get_global_transform().origin)
	
	car.look_at(loc, Vector3(0,1,0))
	car.rotate_y(deg2rad(180))
	# needs to come AFTER rotations
	car.set_translation(local+loc)
	#print("Translation:" + str((local+loc)))
	car.target = target
	# pass intersection data to AI
	car.race_int_path = ai_data
	car.race = self
	
	car.left = false
	
	cars.add_child(car)
	print("Added the car")
	
	# add a minimap arrow
	var minimap = player.get_node("Viewport_root/Viewport/minimap")
	minimap.add_arrow(car)
	
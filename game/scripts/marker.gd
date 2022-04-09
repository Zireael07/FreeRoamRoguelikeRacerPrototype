extends Node3D

# class member variables go here, for example:
var player
var player_script
var time
var count
#start/finish
var finish = false
var start

# test
@export var raceline = PackedVector3Array() #[]
var dist = 0
var target_time = 0

@export var target = Vector3()

func _ready():
	player_script = load("res://car/kinematics/kinematic_vehicle_player.gd")
	count = false
	
	set_process(true)
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func extract_numbers():
	var split = String(get_name()).split(">")
	#print(get_name())
	if split.size() > 1:
		var nrs = split[1].split("-")
		return nrs
	return []

func set_finish(val):
	finish = val

func _on_Area_body_enter( body ):
	if body is CharacterBody3D:
		if body is player_script and not body.get_parent().is_in_group("bike"):
			print("Area3D entered by the player")
			player = body
			
			if player.race != null:
				return # ignore if player is in a race
			
			if finish:
				print("Reached finish marker")
				start.count = false
				
				var msg = body.get_node(^"Messages")
				#msg.set_initial(false)
				var results = player.get_node(^"root").get_node(^"Label timer").get_text()
				msg.set_text("FINISH TIME TRIAL!" + "\n" + results)
				#msg.get_node(^"OK_button").connect(&"pressed", self._on_ok_click)
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
				
				# prize
				if start.time < target_time: # if we beat calculated target time
					player.money += 80
					player.hud.update_money(player.money)
				
				
				#remove finish
				queue_free()
			else:
				var msg = body.get_node(^"Messages")
				#msg.set_initial(false)
				var numbers = extract_numbers()
				var race_name = ""
				if numbers != null:
					race_name = "Route " + str(numbers[0]) + "-" + str(numbers[1])
				msg.set_text("TIME TRIAL RACE! " + "\n" + race_name + "\n" +
				"Drive along the road to the finish marker")
				if not msg.get_node(^"OK_button").is_connected("pressed", Callable(self, "_on_ok_click")):
					print("Not connected")
					# disconnect all others just in case
					#for d in msg.get_node(^"OK_button").get_signal_connection_list("pressed"):
						#print(d["target"])
					#	msg.get_node(^"OK_button").disconnect(&"pressed", d["target"]._on_ok_click)
					msg.get_node(^"OK_button").connect(&"pressed", self._on_ok_click)

				#else:
				#	print("Connected")
				msg.enable_ok(true)
				msg.show()
				
				# show raceline on map
				var track_map = player.get_node(^"Viewport_root/SubViewport/minimap/Container/Node2D2/Control_pos/track")
				track_map.points = track_map.vec3s_convert(raceline)
				# force redraw
				track_map.update()
				
		#else:
		#	print("Area3D entered by a car " + body.get_parent().get_name())
	#else:
	#	print("Area3D entered by something else")


func _on_ok_click():
	count = true
	time = 0.0
	player.get_parent().get_node(^"AnimationPlayer").recording = true
	spawn_finish(self)
	print("Clicked ok!")
	play_replay()
	
	
func _process(delta):
	if count:
		time += delta
		#print("Timer is " + str(time))
		player.get_node(^"root").get_node(^"Label timer").show()
		player.get_node(^"root").update_timer(str(time))
	#else:
	#	print("Count is off")

func _on_Area_body_exit( body ):
	if body is CharacterBody3D:
		if body is player_script:
			#print(" TT Area3D exited by the player")
			player = body
			
			if player.race != null:
				return # ignore if player is in a race
			
			if not finish:
				var msg = body.get_node(^"Messages")
				msg.hide()
				if not count:
					# remove raceline (preview) from map
					var track_map = player.get_node(^"Viewport_root/SubViewport/minimap/Container/Node2D2/Control_pos/track")
					track_map.points = []
					# force redraw
					track_map.update()
				
func spawn_finish(start):
	print("Should be spawning finish")
	
	# because we need distance to calculate target time
	calculate_distance()
	

	
	var loc = target
	# this was BAD, a leak waiting to happen
	#var our = preload("res://objects/marker.tscn")
	#var finish = our.instantiate()
	var finish = self.duplicate()
	finish.set_name("Finish")
	finish.set_position(loc)
	finish.finish = true
	finish.start = start
	finish.target_time = calc_target_time()
	print("Target time: " + str(finish.target_time) + " s")
	#finish.set_val(true)
	
	get_parent().add_child(finish)
	
	var minimap = player.get_node(^"Viewport_root/SubViewport/minimap")
	minimap.add_marker(finish.get_global_transform().origin, minimap.blue_flag)

	
func calculate_distance():
	#var dist = 0
	# because +1
	for i in range(raceline.size()-2):
		var p = raceline[i]
		dist += p.distance_to(raceline[i+1])
	
	print("Length of race: " + str(dist) + "m")
	
func calc_target_time():
	# we assume we need to beat a time set by avg speed
	# speed limit (60 kph) = 16.7 m/s
	var calc = dist/18
	
	# buffer
	
	return calc*1.4

func play_replay():
	if File.new().file_exists("res://replay/replay.tscn"):
		print("We have a replay")
		
		# find the root of the scene
		var cars = player.get_parent().get_parent()
		if cars.has_node("Ghost"):
			print("We already have a ghost")
			cars.get_node(^"Ghost").queue_free()
		
		# load our stuff
		var ghost = preload("res://car/car_replay.tscn")
		var ghost_in = ghost.instantiate()
		ghost_in.set_name("Ghost")
		
		var repl = load("res://replay/replay.tscn")
		var replay = repl.instantiate()
		replay.set_name("replay")
		# test
		replay.set_script(preload("res://replay/replay.gd"))
		
		# place it
		#print("Player position is: " + str(player.get_parent().get_global_transform().origin))
		var rot = player.get_parent().get_global_transform().basis.get_euler()
		#print("Y rot: " + str(player.get_parent().get_global_transform().basis.get_euler()))
		var local = cars.to_local(player.get_parent().get_global_transform().origin)
		#print("Local is: " + str(local))
				
		# fix offset
		ghost_in.set_translation(local)
		ghost_in.set_rotation(rot)
		#ghost_in.set_translation(player.get_parent().get_translation())
		
		cars.add_child(ghost_in)
		ghost_in.add_child(replay)
		#print("Ghost in: " + str(ghost_in.get_global_transform().origin))
		#print("Ghost local: " + str(cars.to_local(ghost_in.get_global_transform().origin)))
		
		# play
		ghost_in.get_node(^"replay").play("BODY")
		

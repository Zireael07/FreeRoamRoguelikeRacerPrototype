# based on Xrayez's gist: https://gist.github.com/Xrayez/ba35197ce6136a50f6d491d5b641236d
# This is a prototype of the state recorder that can be used in a replay system

extends AnimationPlayer

var nodes = []
var animations = {}
# 2D
#var properties = ["global_position", "global_rotation"]
# 3D
var properties = ["translation", "rotation"]

var recording = false
var frame = 0

func _init():
	set_name("state_recorder")

func _ready():
	# Fetch all nodes recursively inside the scene except for StateRecorder 
	# StateRecorder will record all nodes' properties of its parent
	var to_visit = []
	for node in get_parent().get_children():
		# we only want to record BODY
		if node.get_name() == "BODY":
			to_visit.push_back(node)
			nodes.push_back(node)
	nodes.erase(self)
	
	# we only need to record BODY
#	while not to_visit.empty():
#		var current = to_visit.pop_back()
#		for node in current.get_children():
#			# only record visible nodes
#			if "visible" in node and node.is_visible():
#				to_visit.push_back(node)
#				nodes.push_back(node)
	
	# Add properties to be recorded
	for node in nodes:
		#if node is Node2D:
		if node is Spatial:
			# Alas, can't play back multiple animations at once, but nonetheless ...
			var animation = Animation.new()
#			animation.set_step(get_physics_process_delta_time())
			for idx in properties.size():
				var property = properties[idx]
				animation.add_track(Animation.TYPE_VALUE)
				var node_name = str(get_parent().get_path_to(node))
				animation.track_set_path(idx, node_name + ":" + property)
				animations[node] = animation
				add_animation(node_name.replacen('/','.'), animation)
			
func _physics_process(delta):
	if recording:
		# Record states
		#print("Frame" + str(frame))
		#var frame = get_tree().get_frame()
		
		# Uncomment to record every second instead of every frame
	#	if frame % 60 == 0:
		for node in nodes:
			if node is Spatial:
				#print(node.get_name())
			#if node is Node2D:
				for idx in properties.size():
					var property = properties[idx]
					var animation = animations[node]
					animation.track_insert_key(idx, frame * delta, node.get(property))
		
		# increment frames counter
		frame = frame + 1
		#print("Frame inc" + str(frame))

							
func save():
	# prevent races
	recording = false
	
	var dir = Directory.new()
	dir.make_dir("res://replay")
	
	# count frames
	var animation = get_animation("BODY")
	print("Keys: " + str(animation.track_get_key_count(0)))
	print("Counted length" + str(animation.track_get_key_time(0, animation.track_get_key_count(0)-1)))
	animation.length = animation.track_get_key_time(0, animation.track_get_key_count(0)-1)
	
	var ps = PackedScene.new()
	ps.pack(self)
	ResourceSaver.save("res://replay/replay.tscn", ps, ResourceSaver.FLAG_COMPRESS)

func _notification(what):
	# Save replay upon exit
	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			if recording:
				save()
				
extends Control

# class member variables go here, for example:
var loader
var wait_frames
var time_max = 100 # msec
var current_scene

var resource

var loaded = false
var done = false

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	print("Loading screen ready!")
	
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)
	
	goto_scene("res://scenes/scene_procedural.tscn")

	pass

func goto_scene(path): # game requests to switch to this scene
	print("Go to scene: " + str(path))

	loader = ResourceLoader.load_interactive(path)
	if loader == null: # check for errors
		show_error()
		return
	
	set_process(true)

	#current_scene.queue_free() # get rid of the old scene

	# start your "loading..." animation
	#get_node("animation").play("loading")

	wait_frames = 1

func _process(time):
	if wait_frames > 0: # wait for frames to let the "loading" animation to show up
		wait_frames -= 1
		return
	
	
	if loader == null:
		if not loaded: # something went wrong
			# no need to process anymore
			set_process(false)
			return
		else:
			if not done: # we need this to prevent looping for some reason
				#current_scene.queue_free() # get rid of the old scene
				print("Switching to new scene")
				set_new_scene(resource)
				#print("[After set] New root: " + str(get_node("/root").get_name()))
				print("Done loading new scene")
				
				final_progress()
				#wait_frames = 30
				
				done = true
			else: # our job is done, finally!
				current_scene.queue_free() # get rid of the old scene
				print("Free current scene")
		
	else:
		process_loader()

func process_loader():
	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + time_max: # use "time_max" to control how much time we block this thread

		# poll your loader
		var err = loader.poll()

		if err == ERR_FILE_EOF and not loaded:
			finished_loading()
			break
		elif err == OK:
			update_progress()
			# ensure we can see all progress
			#wait_frames = 1
			
		
		else: # error during loading
			show_error()
			loader = null
			break


func finished_loading():
	resource = loader.get_resource()
	
	loader = null
	
#	final_progress()
#	wait_frames = 1
	
	loaded = true

func update_progress():
	var progress = float(loader.get_stage()) / loader.get_stage_count()
	#print("Progress" + str(progress))
	var progress_percent = progress * 100
	#print("Progress is " + String(progress_percent))
	# update your progress bar?
	get_node("ProgressBar").set_value(progress_percent)

	# or update a progress animation?
	#var len = get_node("animation").get_current_animation_length()

	# call this on a paused animation. use "true" as the second parameter to force the animation to update
	#get_node("animation").seek(progress * len, true)

func set_new_scene(scene_resource):
	var new_scene = scene_resource.instance()
	get_node("/root").add_child(new_scene)
	#print("[Set new scene] New root: " + str(get_node("/root").get_name()))
	
func show_error():
	print("Oops! An error happened")

func final_progress():
	get_node("ProgressBar").set_value(99)	
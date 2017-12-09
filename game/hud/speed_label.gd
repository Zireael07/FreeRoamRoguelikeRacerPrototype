extends Control
 

# class member variables go here, for example:
var label = null
var debug_label = null
var fps_label = null
var dist_label = null
var label_timer = null
var label_clock = null

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	label = get_node("Label")
	debug_label = get_node("Label 2")
	fps_label = get_node("Label FPS")
	dist_label = get_node("Label dist")
	label_timer = get_node("Label timer")
	label_clock = get_node("Label clock")

func update_speed(text):
	label.set_text(text)

func update_debug(text):
	debug_label.set_text(text)
	
func update_fps():
	fps_label.set_text(str(Engine.get_frames_per_second()))

func update_distance(text):
	dist_label.set_text(text)
	
func update_timer(text):
	label_timer.set_text("Timer: " + text)
	
func update_clock(text):
	label_clock.set_text(text)
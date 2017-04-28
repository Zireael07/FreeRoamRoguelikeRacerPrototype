#extends CanvasLayer
 

# class member variables go here, for example:
var label = null
var debug_label = null
var fps_label = null
var text 

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	label = get_node("Label")
	debug_label = get_node("Label 2")
	fps_label = get_node("Label FPS")

func update_speed(text):
	label.set_text(text)
	text = text #String(label.get_total_character_count())

func update_debug(text):
	debug_label.set_text(text)
	
func update_fps():
	fps_label.set_text(str(OS.get_frames_per_second()))

#extends CanvasLayer
 

# class member variables go here, for example:
var label = null
var debug_label = null
var text 

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	label = get_node("Label")
	debug_label = get_node("Label 2")

func update_speed(text):
	label.set_text(text)
	text = text #String(label.get_total_character_count())
	##print("Updating speed... " + text)

func update_debug(text):
	debug_label.set_text(text)
	
	
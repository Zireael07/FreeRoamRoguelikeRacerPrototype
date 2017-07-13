extends Control

# class member variables go here, for example:
var label
var button

func _ready():
	
	label = get_node("Label")
	button = get_node("Button")
	
	# Called every time the node is added to the scene.
	# Initialization here
	pass
	
func set_text(text):
	label.set_text(text)


func _on_Button_pressed():
	hide()
	# get_parent().remove_child(self)
	
	pass # replace with function body

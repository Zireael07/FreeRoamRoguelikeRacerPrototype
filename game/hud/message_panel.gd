extends Control

# class member variables go here, for example:
var label
var button
var ok_button

func _ready():
	
	label = get_node("Label")
	button = get_node("Button")
	ok_button = get_node("OK_button")
	
	# Called every time the node is added to the scene.
	# Initialization here
	pass
	
func set_text(text):
	label.set_text(text)


func _on_Button_pressed():
	hide()
	# get_parent().remove_child(self)
	
	pass # replace with function body


func enable_ok(val):
	if val:
		ok_button.show()
		ok_button.set_disabled(false)
	else:
		ok_button.hide()
		ok_button.set_disabled(true)

func _on_OK_button_pressed():
	hide()
	pass # replace with function body

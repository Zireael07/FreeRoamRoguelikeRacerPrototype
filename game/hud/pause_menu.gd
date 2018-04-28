extends Control

# class member variables go here, for example:

func _ready():
	#hide()
	
	set_process_input(true)
	#pass
	
func _input(event):
	# we cannot pause/unpause if we're dead
	if (Input.is_action_pressed("ui_cancel")) and get_parent().health > 0:
		if (not get_tree().is_paused()):
			show()
			get_tree().set_pause(true)
		else:
			hide()
			get_tree().set_pause(false)

func _on_CheckGIButton_pressed():
	var root = get_parent().get_parent().get_parent()
	# disable GI
	if root.get_node("GIProbe").is_visible():
		root.get_node("GIProbe").hide()
	else:
		root.get_node("GIProbe").show()
	
	#pass # replace with function body


func _on_Button_pressed():
	print("Pressed resume")
	get_tree().set_pause(false)
	
	#hide the menu again
	hide()
	pass # replace with function body

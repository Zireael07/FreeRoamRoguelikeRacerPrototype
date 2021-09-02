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

#func _on_CheckGIButton_pressed():
#	var root = get_parent().get_parent().get_parent()
#	# disable GI
#	if root.get_node("GIProbe").is_visible():
#		root.get_node("GIProbe").hide()
#	else:
#		root.get_node("GIProbe").show()
#
#	#pass # replace with function body


func _on_Button_pressed():
	#print("Pressed resume")
	get_tree().set_pause(false)
	
	#hide the menu again
	hide()
	pass # replace with function body


func _on_MouseSteerButton_pressed():
	if !get_parent().mouse_steer:
		get_parent().mouse_steer = true
		get_parent().get_node("Joystick").show()
	else:
		get_parent().mouse_steer = false
		get_parent().get_node("Joystick").hide()
	
	
	#pass # Replace with function body.


func _on_Button2_pressed():
	hide()
	
	##GUI
	var h = preload("res://hud/info_panel.tscn")
	var hud = h.instance()
	get_parent().add_child(hud)
	
	# update the values
	var root = get_node("/root/Navigation")
	var txt = "Roads discovered: " + str(root.discovered_roads.size()) +"/12"
	hud.get_node("Label").set_text(txt)
	
	hud.show()

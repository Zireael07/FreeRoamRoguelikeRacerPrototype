extends Container

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	hide()
	
	set_process_input(true)
	pass
	
func _input(event):
	if (Input.is_action_pressed("ui_cancel")):
		if (not get_tree().is_paused()):
			show()
			get_tree().set_pause(true)
		else:
			hide()
			get_tree().set_pause(false)
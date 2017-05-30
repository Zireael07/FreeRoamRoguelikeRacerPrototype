extends Button

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass


func _on_resume_button_pressed():
	get_tree().set_pause(false)
	
	#hide the menu again
	get_parent().hide()
	
	pass

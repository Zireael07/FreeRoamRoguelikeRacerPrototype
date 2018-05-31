extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _on_Button_pressed():
	print("Going back to the city...")
	
	get_parent().go_back()
	
	pass # replace with function body

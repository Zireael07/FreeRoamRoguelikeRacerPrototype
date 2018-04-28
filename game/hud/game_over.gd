extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	# pause and show
	show()
	get_tree().set_pause(true)
	#pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_Button_Quit_pressed():
	get_tree().quit() # quit game
	#pass # replace with function body

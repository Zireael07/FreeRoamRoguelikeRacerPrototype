extends Button

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass


func _on_new_game_pressed():
	#print("Pressed button")
	#get_tree().change_scene("res://scenes/Main.tscn")
	get_tree().change_scene("res://hud/loading_screen.tscn")
	
	pass

extends Control

# class member variables go here, for example:
var player

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _on_Button_pressed():
	print("Going back to the city...")
	
	get_parent().go_back()
	
	pass # replace with function body


func _on_BrakeButton_pressed():
	player.braking_force_mult = 6


func _on_BrakeButton2_pressed():
	player.braking_force_mult = 8


func _on_TireButton_pressed():
	print("Pressed tire")
	player.get_node("wheel1").set_friction_slip(1.5)
	player.get_node("wheel2").set_friction_slip(1.5)
	player.get_node("wheel3").set_friction_slip(1.5)
	player.get_node("wheel4").set_friction_slip(1.5)


func _on_EngineButton_pressed():
	player.engine_force_mult = 1.5
	#pass # replace with function body


func _on_EngineButton2_pressed():
	player.engine_force_mult = 2
	#pass # replace with function body

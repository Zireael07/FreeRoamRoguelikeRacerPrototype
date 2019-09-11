extends Control

# Declare member variables here. Examples:

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	var player_rot = get_tree().get_nodes_in_group("player")[0].get_child(0).get_rotation()
	#var player_rot = get_parent().get_parent().get_parent().get_parent().get_rotation()
	var map_rot = player_rot.y
	
	#this resolves the gimbal lock issues
	if (player_rot.x < -deg2rad(150) or player_rot.x > deg2rad(150)) and (player_rot.z < - deg2rad(150) or player_rot.z > deg2rad(150)):
		map_rot = deg2rad(180)+player_rot.y #1.02
	
	set_rotation(map_rot)
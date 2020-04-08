# rotates the compass only
extends Control

# Declare member variables here. Examples:

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	var player = get_tree().get_nodes_in_group("player")[0].get_child(0)
	# https://godotengine.org/qa/11335/getting-the-y-axis-rotation-of-an-object-in-3d
	var player_rot = player.get_global_transform().basis.z.angle_to(Vector3(0,0,1))
	#print("player rot: " + str(player_rot))
	# keep E at top
	#player_rot = player_rot - PI
	
	#var forward_global = player.get_global_transform().xform(Vector3(0, 0, 2))
	#var forward_vec = forward_global-player.get_global_transform().origin
	#var player_rot = forward_vec.angle_to(Vector3(0,0,1))
	
	#var player_rot = get_tree().get_nodes_in_group("player")[0].get_child(0).get_rotation()
	var map_rot = player_rot #.y
	
	#this resolves the gimbal lock issues
	#if (player_rot.x < -deg2rad(150) or player_rot.x > deg2rad(150)) and (player_rot.z < - deg2rad(150) or player_rot.z > deg2rad(150)):
	#	map_rot = deg2rad(180)+player_rot.y #1.02
	
	set_rotation(map_rot)

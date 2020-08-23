extends Node2D

# class member variables go here, for example:

func _ready():
	#set_process_input(true)
	#set_physics_process(true)
	set_process(true)
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
	var player_rot = get_tree().get_nodes_in_group("player")[0].get_child(0).get_rotation()
	#var player_rot = get_parent().get_parent().get_parent().get_parent().get_rotation()
	var map_rot = player_rot.y

	#this resolves the gimbal lock issues
	if (player_rot.x < -deg2rad(150) or player_rot.x > deg2rad(150)) and (player_rot.z < - deg2rad(150) or player_rot.z > deg2rad(150)):
		map_rot = deg2rad(180)+player_rot.y #1.02

	set_rotation(map_rot)
	
	var player = get_tree().get_nodes_in_group("player")[0].get_child(0)
#	var pl_tr = player.get_global_transform()
#	var axis = pl_tr + Vector3(0,0,)
	
	



#func _physics_process(delta):
#	var player_rot = get_tree().get_nodes_in_group("player")[0].get_child(0).get_rotation()
#	#var player_rot = get_parent().get_parent().get_parent().get_parent().get_rotation()
#	var map_rot = -player_rot.y
#
#	#this resolves the gimbal lock issues
#	if (player_rot.x < -deg2rad(150) or player_rot.x > deg2rad(150)) and (player_rot.z < - deg2rad(150) or player_rot.z > deg2rad(150)):
#		map_rot = deg2rad(180)+player_rot.y #1.02
#
#	set_rotation(map_rot)
#
#	#print("Player rotation is " + String(player_rot))

extends Camera2D

# class member variables go here, for example:
var map_rot = 0
var arr_rot = 0

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _physics_process(delta):
	var pan = calc_panning()
	#print(pan)
	#set_offset(Vector2(pan[0], pan[1]))
	set_position(Vector2(pan[0], pan[1]))
	#var player_coord = get_tree().get_nodes_in_group("player")[0].get_child(0).get_global_transform().origin
	
	#print(player_coord)

	#var player_rot = get_tree().get_nodes_in_group("player")[0].get_child(0).get_rotation()
	#var player_rot = get_parent().get_parent().get_parent().get_parent().get_rotation()
	var player = get_tree().get_nodes_in_group("player")[0].get_child(0)
	# https://godotengine.org/qa/11335/getting-the-y-axis-rotation-of-an-object-in-3d
	var player_rot = player.get_global_transform().basis.z.angle_to(Vector3(0,0,1))
	
	map_rot = player_rot #.y
	#print("Map rot: " + str(map_rot))
	
	#this resolves the gimbal lock issues
	#if (player_rot.x < -deg2rad(150) or player_rot.x > deg2rad(150)) and (player_rot.z < - deg2rad(150) or player_rot.z > deg2rad(150)):
	#	map_rot = deg2rad(180)+player_rot.y #1.02
	
	# For rotation to work, there must be NO Controls as it's parent/grandparent, in other words up the node tree
	# siblings are fine
	
	set_rotation(map_rot)
	
	# rotate the player arrow
	#arr_rot = map_rot
#	if player_rot.y > deg2rad(30) and player_rot.y < deg2rad(120) or player_rot.y > deg2rad(-120) and player_rot.y < deg2rad(-30):
#		arr_rot = arr_rot+deg2rad(90)
#	if abs(player_rot.y) < deg2rad(48):
#		arr_rot = arr_rot+deg2rad(180)
	
	#get_node("player").set_rotation(arr_rot)

func calc_panning():
	#print("Minimap offset is " + String(minimap_bg.uv_offset))
	var player_coord = get_tree().get_nodes_in_group("player")[0].get_child(0).get_global_transform().origin
	#var player_coord = get_parent().get_parent().get_global_transform().origin
	#print("Player coords is " + String(player_coord))
	#to move map left, the value must be negative
	var panning_x = -player_coord.x
	#to move map up from our perspective, the value must be negative
	var panning_y = -player_coord.z
	#print("Panning " + String(panning_x) + " " + String(panning_y))
	return [panning_x, panning_y]


#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

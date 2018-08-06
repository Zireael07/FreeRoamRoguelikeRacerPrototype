extends Camera2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

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

	var player_rot = get_tree().get_nodes_in_group("player")[0].get_child(0).get_rotation()
	#var player_rot = get_parent().get_parent().get_parent().get_parent().get_rotation()
	var map_rot = player_rot.y
	
	#this resolves the gimbal lock issues
	if (player_rot.x < -deg2rad(150) or player_rot.x > deg2rad(150)) and (player_rot.z < - deg2rad(150) or player_rot.z > deg2rad(150)):
		map_rot = deg2rad(180)+player_rot.y #1.02
	
	set_rotation(-map_rot)

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

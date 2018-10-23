extends Node2D

# class member variables go here, for example:
var AIs = PoolStringArray()
#var player_pos = Vector2(110, 110)
var minimap_bg
var cam2d
var attach


# for storing positions
var temp_positions = Array()
var positions = Array()

# for static markers (races, POIs)
var marker_pos = []
var markers = []

# gfx
var blue_flag

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	positions.resize(0)
	
	var arrow = preload("res://hud/minimap_arrow_big_64 - bordered grayscale.png")
	var player_arrow = preload("res://hud/minimap_arrow_big_64 - cyan.png")
	blue_flag = preload("res://hud/flag.png")
	#var red_flag = preload("res://hud/flag_red.png")
	
	cam2d = get_node("Container/Node2D2/Control_pos/Camera2D")
	#print(cam2d.get_name())
	
	#attach = get_child(0)
	attach = get_node("Container/Node2D2/Control_pos/attach")
	
	getPositions()
	
	setupMinimap(arrow, player_arrow)
	
	#get the minimap
	#minimap_bg = get_child(0).get_child(0).get_child(0)
	
	set_process(true)
	pass

func setupMinimap(arrow, player_arrow):
	##we're child of player, AI are siblings of player
	var AI = get_tree().get_nodes_in_group("player")[0].get_parent().get_node("AI")
	var AI2 = get_tree().get_nodes_in_group("player")[0].get_parent().get_node("AI2")
	# TODO: clean this up!
	#var AI = get_parent().get_parent().get_parent().get_parent().get_parent().get_node("AI")
	#var AI2 = get_parent().get_parent().get_parent().get_parent().get_parent().get_node("AI2")
	#var AI1 = get_parent().get_parent().get_parent().get_node("AI1")
	
	if (AI != null):
		AIs.push_back("AI")
	if (AI2 != null):
		AIs.push_back("AI2")
	#if (AI1 != null):
	#	AIs.push_back("AI1")
	
	for index in range(AIs.size()):
		var tex = TextureRect.new()
		tex.set_texture(arrow)
		tex.set_name(AIs[index])
		tex.set_scale(Vector2(0.5, 0.5))
		
		attach.add_child(tex)
		#add the arrows beneath the camera
		#cam2d.add_child(tex)
	
	# markers
	var markers = get_tree().get_nodes_in_group("marker")
	
	for e in markers:
		#print("We have a marker " + e.get_name())
		add_marker(e.get_global_transform().origin, blue_flag)
	
	
	# is last because needs to be on top of everything else
	#add player arrow
	var player_tex = TextureRect.new()
	player_tex.set_texture(player_arrow)
	player_tex.set_name("player")
	player_tex.set_scale(Vector2(0.5, 0.5))
	cam2d.add_child(player_tex)
	# so that the player is always centered
	player_tex.set_position(Vector2(-16,-16))
	
	#player_tex.set_position(player_pos)
	#get_child(0).add_child(player_tex)


func add_marker(pos, flag):
	var marker_tex = TextureRect.new()
	marker_tex.set_texture(flag)
	#marker_tex.set_pos(pos3d_to_gamemap_point(Vector3(pos)))
	#marker_tex.set_scale(Vector2(0.5, 0.5))
	attach.add_child(marker_tex)
	#cam2d.add_child(marker_tex)
	#marker_tex.set_position(Vector2(-16-pos.x, -16-pos.z))
	# fudge factor necessary
	marker_tex.set_position(Vector2(-pos.x, -pos.z-16))
	#print("For pos " + str(pos) + "marker pos is " + str(marker_tex.get_position()))
	marker_pos.push_back(pos)
	markers.push_back(marker_tex.get_name())


# get the positions we need for actual mapgen
func add_positions(pos):
	#print("Adding positions")
	var temp = []
	
	# simple (add just the positions)
	#for i in range(pos.size():
	#	add(pos[i])
	
	# store positions per road
	for i in range (pos.size()):
		#if add(pos[i]):
		temp.push_back(pos[i])
	
	positions.append(temp)

func getPositions():
	#get_tree().call_group(0, "roads", "send_positions", self)
	var roads = get_tree().get_nodes_in_group("roads")
	for r in roads:
		r.send_positions(self)
		
	print("Should have positions")
	
func _process(delta):
	#var player_coord = get_tree().get_nodes_in_group("player")[0].get_child(0).get_global_transform().origin
	#cam2d.get_node("player").set_position(Vector2(-16-player_coord.x, -16-player_coord.z))
	for index in range(AIs.size()):
		#the actual AI lives in the child of the spatial
		var AI_node = get_tree().get_nodes_in_group("player")[0].get_parent().get_node(AIs[index]).get_child(0)
		
		var AI_pos = AI_node.get_global_transform().origin
		
		#print("AI pos: " + str(AI_pos) + " map pos " + str(Vector2(-16-AI_pos.x, -AI_pos.z)))
		
		attach.get_child(index).set_position(Vector2(-16-AI_pos.x, -AI_pos.z))
		
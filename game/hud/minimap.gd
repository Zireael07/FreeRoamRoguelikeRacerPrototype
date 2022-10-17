# obsolete, kept only for comparison purposes
# use camera_minimap instead
extends Control

# class member variables go here, for example:
var AIs = []
var player_pos = Vector2(110, 110)
var minimap_bg

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
	
	getPositions()
	
	setupMinimap(arrow, player_arrow)
	
	#get the minimap
	#minimap_bg = get_child(0).get_child(0).get_child(0)
	
	set_process(true)
	pass

func setupMinimap(arrow, player_arrow):
	AIs = get_tree().get_nodes_in_group("AI")
	
	for index in range(AIs.size()):
		var tex = TextureRect.new()
		tex.set_texture(arrow)
		tex.set_name(AIs[index])
		tex.set_scale(Vector2(0.5, 0.5))
		#add the arrows beneath the container
		get_child(0).add_child(tex)
	
	# markers
	var markers = get_tree().get_nodes_in_group("marker")
	
	for e in markers:
		#print("We have a marker " + e.get_name())
		add_marker(e.get_global_transform().origin)
	
	
	# is last because needs to be on top of everything else
	#add player arrow
	var player_tex = TextureRect.new()
	player_tex.set_texture(player_arrow)
	player_tex.set_name("player")
	player_tex.set_scale(Vector2(0.5, 0.5))
	player_tex.set_position(player_pos)
	get_child(0).add_child(player_tex)


func add_marker(pos):
	var marker_tex = TextureRect.new()
	marker_tex.set_texture(blue_flag)
	#marker_tex.set_pos(pos3d_to_gamemap_point(Vector3(pos)))
	#marker_tex.set_scale(Vector2(0.5, 0.5))
	get_child(0).add_child(marker_tex)
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
	for index in range(AIs.size()):
		#the actual AI lives in the child of the spatial
		var AI_node = AIs[index].get_child(0)

		var rel_loc = get_AI_rel_loc(AI_node)
		
		#arrows are children of container, which is below us
		var dot = get_child(0).get_node(AIs[index])
		if dot != null:
			var dot_offset = get_AI_dot_loc(rel_loc)
			var dot_pos = player_pos-dot_offset
			dot.set_position(dot_pos)
			var dist = get_AI_dot_dist(dot)
			#hide those arrows that would go out of map range
			if dist > 100:
				dot.hide()
			else:
				dot.show()
	
	# handle the markers
	for index in range(markers.size()):
		var dot = get_child(0).get_node(markers[index])
		if dot != null:
			var rel_loc = get_point_rel_loc(marker_pos[index])
			var dot_offset = get_AI_dot_loc(rel_loc)
			var dot_pos = player_pos-dot_offset
			# 32 is the icon size, so let's fix the slight offset
			dot_pos = Vector2(dot_pos.x+32/2, dot_pos.y)
			dot.set_position(dot_pos)
			var dist = get_AI_dot_dist(dot)
			#hide those arrows that would go out of map range
			if dist > 100:
				dot.hide()
			else:
				dot.show()
	
	
	var calc_offset = calc_panning()
	
	minimap_bg.get_material().set_shader_parameter("X", calc_offset[0])
	minimap_bg.get_material().set_shader_parameter("Y", calc_offset[1])
	
func calc_panning():
	#print("Minimap offset is " + String(minimap_bg.uv_offset))
	var player_coord = get_tree().get_nodes_in_group("player")[0].get_child(0).get_global_transform().origin
	#var player_coord = get_parent().get_parent().get_global_transform().origin
	#print("Player coords is " + String(player_coord))
	#to move map left, the value must be negative
	var panning_x = player_coord.x * -minimap_bg.uv_offset
	#to move map up from our perspective, the value must be negative
	var panning_y = player_coord.z * -minimap_bg.uv_offset
	#print("Panning " + String(panning_x) + " " + String(panning_y))
	return [panning_x, panning_y]

func get_point_rel_loc(global_loc):
	var player_tr = get_tree().get_nodes_in_group("player")[0].get_child(0).get_global_transform()
	#var player_tr = get_parent().get_parent().get_global_transform()
	
	var rel_loc = global_loc * player_tr
	return rel_loc
	
func get_AI_rel_loc(AI):
	var global_loc = AI.get_global_transform().origin
	var player_tr = get_tree().get_nodes_in_group("player")[0].get_child(0).get_global_transform()
	#var player_tr = get_parent().get_parent().get_global_transform()
	
	var rel_loc = global_loc * player_tr
		
	return rel_loc

func get_AI_dot_loc(rel_loc):
	var dot_loc = Vector2(rel_loc.x, rel_loc.z)
	return dot_loc

func get_AI_dot_dist(dot):
	#print(dot.get_name() + " dot pos is " + String(dot.get_pos()))
	return player_pos.distance_to(dot.get_position())

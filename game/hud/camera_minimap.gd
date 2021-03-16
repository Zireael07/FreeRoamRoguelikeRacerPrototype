extends Node2D

# class member variables go here, for example:
#var AIs = PoolStringArray()
var AIs = []

#var player_pos = Vector2(110, 110)
var minimap_bg
var cam2d
var attach


# for storing positions
var temp_positions = Array()
var positions = Array()
var intersections = Array()

# for static markers (races, POIs)
var marker_pos = []
var markers = []
var mapping_marker = {}

# AI car arrows
var arrows = []
var mapping_arrows = {}

# gfx
var blue_flag
var red_flag
var poi_marker
var arrow
# a scene
var cop_arrow_sc
var cop_arrow

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	positions.resize(0)
	
	#arrow = preload("res://hud/minimap_arrow_big_64 - bordered grayscale.png")
	arrow = preload("res://hud/grey_circle.png")
	#var player_arrow = preload("res://hud/minimap_arrow_big_64 - cyan.png")
	var player_arrow = arrow
	blue_flag = preload("res://hud/flag.png")
	red_flag = preload("res://hud/flag_red.png")
	poi_marker = preload("res://hud/big marker.png")
	
	cop_arrow_sc = preload("res://hud/cop_arrow.tscn")
	
	cam2d = get_node("Container/Node2D2/Control_pos/Camera2D")
	#print(cam2d.get_name())
	
	#attach = get_child(0)
	attach = get_node("Container/Node2D2/Control_pos/attach")
	
	getPositions()
	
	getIntersections()
	
	setupMinimap(arrow, player_arrow)
	
	#get the minimap
	#minimap_bg = get_child(0).get_child(0).get_child(0)
	
	set_process(true)
	pass

func setupMinimap(arrow, player_arrow):
	AIs = get_tree().get_nodes_in_group("AI")
	
	for index in range(AIs.size()):
		var AI = AIs[index]
		
		var tex = TextureRect.new()
		tex.set_texture(arrow)
		tex.set_name("traffic-AI")
		#tex.set_name(AIs[index].get_name())

		# police
		if AI.is_in_group("cop"):
			tex = cop_arrow_sc.instance()
#			tex.set_modulate(Color(0,0,1))
			tex.set_name("cop-AI")
			cop_arrow = tex
		
		# so that the arrow is always centered on the road
		tex.set_scale(Vector2(0.5, 0.5))
		tex.set_position(Vector2(-9,-9))
		tex.set_pivot_offset(Vector2(9,9))
		attach.add_child(tex)
		arrows.append(tex)
		#add the arrows beneath the camera
		#cam2d.add_child(tex)
	
#		if AI.is_in_group("cop"):
#			# test, make it flash!
#			tex.get_child(0).play("cop_flash")
	
	# markers
	add_event_markers()
	var pois = get_tree().get_nodes_in_group("poi")
	for p in pois:
		add_marker(p.get_global_transform().origin, poi_marker, Vector2(-16,-16))
	
	
	# is last because needs to be on top of everything else
	#add player arrow
	var player_tex = TextureRect.new()
	player_tex.set_texture(player_arrow)
	player_tex.set_name("player")
	player_tex.set_scale(Vector2(0.5, 0.5))
	player_tex.set_modulate(Color(0,1,1)) # cyan
	cam2d.add_child(player_tex)
	# so that the player is always centered
	player_tex.set_position(Vector2(-9,-9)) # used to be 16 for the arrows
	player_tex.set_pivot_offset(Vector2(9,9))
	
	#player_tex.set_position(player_pos)
	#get_child(0).add_child(player_tex)


func add_marker(pos, flag, offset=Vector2(0,0)):
	var marker_tex = TextureRect.new()
	marker_tex.set_texture(flag)
	marker_tex.set_name("marker")
	#marker_tex.set_pos(pos3d_to_gamemap_point(Vector3(pos)))
	#marker_tex.set_scale(Vector2(0.5, 0.5))
	attach.add_child(marker_tex)
	#cam2d.add_child(marker_tex)
	#marker_tex.set_position(Vector2(-16-pos.x, -16-pos.z))
	# fudge factor necessary
	marker_tex.set_position(Vector2(-pos.x, -pos.z)+offset)
	#marker_tex.set_position(Vector2(-pos.x, -pos.z-16))
	#print("For pos " + str(pos) + "marker pos is " + str(marker_tex.get_position()))
	marker_pos.push_back(pos)
	markers.push_back(marker_tex)
	mapping_marker[pos] = marker_tex

func remove_marker(pos):
	print("Removing marker for: " + str(pos))
	if marker_pos.find(pos) != -1:
		marker_pos.remove(marker_pos.find(pos))
	if mapping_marker.has(pos) && mapping_marker[pos] != null:
		var marker = mapping_marker[pos]
		markers.remove(markers.find(marker))
		attach.remove_child(marker)
		# clear the mapping
		mapping_marker[pos] = null	

func add_arrow(AI, racer=true):
	var tex = TextureRect.new()
	tex.set_texture(arrow)
	tex.set_name("traffic-AI")
	#tex.set_name(AIs[index].get_name())
	tex.set_scale(Vector2(0.5, 0.5))
	if racer:
		tex.set_modulate(Color(1,0,0))
		tex.set_name("racer-AI")
		# add to mapping
		mapping_arrows[AI] = tex
	
	attach.add_child(tex)
	arrows.append(tex)
	
	# add to AI list
	AIs.append(AI)

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

func add_intersection(pos):
	intersections.append(pos)

func getIntersections():
	var inters = get_tree().get_nodes_in_group("intersection")
	for i in inters:
		i.send_position(self)
	
func _process(delta):
	#var player_coord = get_tree().get_nodes_in_group("player")[0].get_child(0).get_global_transform().origin
	#cam2d.get_node("player").set_position(Vector2(-16-player_coord.x, -16-player_coord.z))
	for index in range(AIs.size()):
		#the actual AI lives in the child of the spatial
		var AI_node = AIs[index].get_child(0)
		
		var AI_pos = AI_node.get_global_transform().origin
		
		#print("AI pos: " + str(AI_pos) + " map pos " + str(Vector2(-16-AI_pos.x, -AI_pos.z)))
		
		var arr = arrows[index]
		arr.set_position(Vector2(-16-AI_pos.x, -AI_pos.z))
		#attach.get_child(index).set_position(Vector2(-16-AI_pos.x, -AI_pos.z))
		
func flash_cop_arrow():
	cop_arrow.get_child(0).play("cop_flash")
	
func stop_cop_arrow():
	cop_arrow.get_child(0).stop()
	cop_arrow.set_modulate(Color(0,0,1))

func remove_arrow(AI):
	if mapping_arrows.has(AI):
		print("Found an arrow")
		
		# remove AI
		AIs.remove(AIs.find(AI))
		
		attach.remove_child(mapping_arrows[AI])
		arrows.remove(arrows.find(mapping_arrows[AI]))
		# remove the mapping
		mapping_arrows[AI] = null

func add_event_markers():
	var markers = get_tree().get_nodes_in_group("marker")
	
	for e in markers:
		if not e.is_in_group("race_marker"):
			#print("We have a marker " + e.get_name())
			add_marker(e.get_global_transform().origin, blue_flag, Vector2(0, -16))
		else:
			add_marker(e.get_global_transform().origin, red_flag, Vector2(0,-16))

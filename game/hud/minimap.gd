extends Control

# class member variables go here, for example:
var AIs = StringArray()
var player_pos = Vector2(110, 110)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	var arrow = preload("res://hud/minimap_arrow_big_64 - bordered grayscale.png")
	var player_arrow = preload("res://hud/minimap_arrow_big_64 - cyan.png")
	
	##we're child of player, AI are siblings of player
	var AI = get_parent().get_parent().get_parent().get_node("AI")
	var AI2 = get_parent().get_parent().get_parent().get_node("AI2")
	#var AI1 = get_parent().get_parent().get_parent().get_node("AI1")
	
	if (AI != null):
		AIs.push_back("AI")
	if (AI2 != null):
		AIs.push_back("AI2")
	#if (AI1 != null):
	#	AIs.push_back("AI1")
	
	for index in range(AIs.size()):
		var tex = TextureFrame.new()
		tex.set_texture(arrow)
		tex.set_name(AIs[index])
		tex.set_scale(Vector2(0.5, 0.5))
		#add the arrows beneath the container
		get_child(0).add_child(tex)
	
	#add player arrow
	var player_tex = TextureFrame.new()
	player_tex.set_texture(player_arrow)
	player_tex.set_name("player")
	player_tex.set_scale(Vector2(0.5, 0.5))
	player_tex.set_pos(player_pos)
	get_child(0).add_child(player_tex)
	
	
	set_process(true)
	pass

func _process(delta):
	for index in range(AIs.size()):
		#the actual AI lives in the child of the spatial
		var AI_node = get_parent().get_parent().get_parent().get_node(AIs[index]).get_child(0)
		var rel_loc = get_AI_rel_loc(AI_node)
		
		#arrows are children of container, which is below us
		var dot = get_child(0).get_node(AIs[index])
		if dot != null:
			var dot_offset = get_AI_dot_loc(rel_loc)
			var dot_pos = player_pos-dot_offset
			dot.set_pos(dot_pos)
			var dist = get_AI_dot_dist(dot)
			#hide those arrows that would go out of map range
			if dist > 100:
				dot.hide()
			else:
				dot.show()
	
func get_AI_rel_loc(AI):
	var global_loc = AI.get_global_transform().origin
	var player_tr = get_parent().get_global_transform()
	
	var rel_loc = player_tr.xform_inv(global_loc)
		
	return rel_loc

func get_AI_dot_loc(rel_loc):
	var dot_loc = Vector2(rel_loc.x, rel_loc.z)
	return dot_loc

func get_AI_dot_dist(dot):
	#print(dot.get_name() + " dot pos is " + String(dot.get_pos()))
	return player_pos.distance_to(dot.get_pos())
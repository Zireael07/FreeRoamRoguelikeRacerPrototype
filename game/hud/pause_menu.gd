extends Control

# class member variables go here, for example:

func _ready():
	#hide()
	
	set_process_input(true)
	#pass
	
func _input(event):
	# we cannot pause/unpause if we're dead
	if (Input.is_action_pressed("ui_cancel")) and get_parent().health > 0:
		if (not get_tree().is_paused()):
			show()
			get_tree().set_pause(true)
		else:
			hide()
			get_tree().set_pause(false)

#func _on_CheckGIButton_pressed():
#	var root = get_parent().get_parent().get_parent()
#	# disable GI
#	if root.get_node("GIProbe").is_visible():
#		root.get_node("GIProbe").hide()
#	else:
#		root.get_node("GIProbe").show()
#
#	#pass # replace with function body


func _on_Button_pressed():
	#print("Pressed resume")
	get_tree().set_pause(false)
	
	#hide the menu again
	hide()
	pass # replace with function body


func _on_MouseSteerButton_pressed():
	if !get_parent().mouse_steer:
		get_parent().mouse_steer = true
		get_parent().get_node("Joystick").show()
	else:
		get_parent().mouse_steer = false
		get_parent().get_node("Joystick").hide()
	
	
	#pass # Replace with function body.

# exploration screen stuff
func _on_Button2_pressed():
	hide()
	
	var player = get_tree().get_nodes_in_group("player")[0]
	# list of intersection global positions
	var intersections = player.get_node("BODY/Viewport_root/Viewport/minimap").intersections
	#the camera seems to be offset by this value from minimap center
	# experimentally determined (note it's different from MapView.gd for some reason)
	var mmap_offset = Vector2(30,-100)
	# intersection1, on which the map is centered at game start
	var inter1 = Vector2(intersections[1].x, intersections[1].z)
	
	##GUI
	var h = preload("res://hud/info_panel.tscn")
	var hud = h.instance()
	get_parent().add_child(hud)
	
	var c = preload("res://hud/card.tscn")
	
	# update the values
	var root = get_node("/root/Navigation")
	var txt = "Roads discovered: " + str(root.discovered_roads.size()) +"/12"
	hud.get_node("Label").set_text(txt)
	
	for i in range(root.discovered_roads.size()):
		var card = c.instance()
		hud.get_node("Control").add_child(card)
		card.set_position(Vector2(i*210, 0))
		#print(root.discovered_roads.keys()[i])
		card.get_node("VBoxContainer/Label").set_text(root.discovered_roads.keys()[i])
		
		# FIXME: stop leaking car positions, set a fresh world (just the map bg)
		# set world
		card.get_node("VBoxContainer/MapView/Viewport").world_2d = player.get_node("BODY/Viewport_root/Viewport").world_2d
	
		# extract intersection numbers
		var ret = []
		var strs = root.discovered_roads.keys()[i].split("-")
		# convert to int
		ret.append(int(strs[0].lstrip("Road ")))
		ret.append(int(strs[1]))
	
		# center on the road
		var inter = intersections[ret[0]]
		print("Inter0: " + str(inter))
		# pretend it's 2d
		var inter_pos = Vector2(inter.x, inter.z)-inter1
		inter = intersections[ret[1]]
		print("Inter1: " + str(inter))
		var inter_pos2 = Vector2(inter.x, inter.z)-inter1
		var off = (inter_pos+inter_pos2)/2
		print("Off: " + str(off))
		card.get_node("VBoxContainer/MapView/Viewport/Camera2D").offset = mmap_offset-off 
	
	hud.show()

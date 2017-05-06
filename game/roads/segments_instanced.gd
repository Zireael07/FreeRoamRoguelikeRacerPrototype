tool

extends Position3D

# class member variables go here, for example:
export(int) var numSegments = 2
var road
var road_left

export(Vector3Array) var positions = Vector3Array()
export(Vector3Array) var ends = Vector3Array()


func _ready():
	#positions.clear()
	#clearChildren()
	
	
	# Called every time the node is added to the scene.
	road = preload("res://roads/road_segment.tscn")
	road_left = preload("res://roads/road_segment_left.tscn")
	
	# Initialization here
	for index in range (numSegments):
		placeRoad(index)
	
	pass

func clearChildren():
	for index in get_children():
		index.queue_free()


func get_prev_segment(index):
	if get_node("Road_instance"+String(index-1)):
		return get_node("Road_instance"+String(index-1))

func setupRoad(index, left):
	if (left):
		var road_node_left = road_left.instance()
		road_node_left.set_name("Road_instance" + String(index))
		add_child(road_node_left)
		return road_node_left
	else:
		var road_node = road.instance()
		road_node.set_name("Road_instance" + String(index))
		add_child(road_node)
		return road_node

func placeRoad(index):
	if (get_node("Road_instance"+String(index)) == null):
		
		var road_node
		
		if (index == 0):
			road_node = setupRoad(index, false)
			positions.push_back(road_node.get_translation())
			ends.push_back(road_node.get_child(0).get_child(0).relative_end)
#			road_node = road.instance()
#			road_node.set_name("Road_instance" + String(index))
#			add_child(road_node)
		else:
			if (index % 2 > 0): ##odd
				var prev = get_prev_segment(index)
				if (prev != null):
					#print("Previous segment is " + prev.get_name())
					var prev_loc = prev.get_translation()
					var end_loc = prev.get_child(0).get_child(0).relative_end
					var loc = prev_loc + end_loc
					if (prev_loc != Vector3(0,0,0)):
						print("Previous location is not 0,0,0")
						loc = Vector3(prev_loc.x-end_loc.x, 0, prev_loc.z-end_loc.z)
					print("Previous segment " + prev.get_name() + " location is " + String(prev_loc))
					
					print("Location is " + String(loc))
					road_node = setupRoad(index, true)
					if (prev_loc != Vector3(0,0,0)):
						road_node.set_translation(loc)
					else:
						road_node.set_translation(-loc)
					positions.push_back(road_node.get_translation())
					ends.push_back(road_node.get_child(0).get_child(0).relative_end)
				else:
					print("No previous segment found")
			else: #even
				var prev = get_prev_segment(index)
				if (prev != null):
					var prev_loc = positions[index-1]
					#var prev_loc = prev.get_translation()
					var end_loc = ends[index-1]
					#var end_loc = prev.get_child(0).get_child(0).relative_end
					var loc = prev_loc - end_loc
					#var loc = Vector3(prev_loc.x + end_loc.x, prev_loc.y + end_loc.y, prev_loc.z+end_loc.z)
					print("Previous segment is " + prev.get_name() + " location " + String(prev_loc) + " end " + String(end_loc));
					#print("End of previous location is " + String(prev.get_child(0).get_child(0).relative_end))
					#print("Previous segment location is " + String(prev_loc))
					print("Location is " + String(loc))
					
					#if (prev_loc !
					
					
					road_node = road.instance()
					road_node.set_name("Road_instance" + String(index))
					add_child(road_node)
					
					#road_node = setupRoad(index, false)
					road_node.set_translation(loc)
					positions.push_back(road_node.get_translation())
					ends.push_back(road_node.get_child(0).get_child(0).relative_end)
				else:
					print("No previous segment found")
			
		if get_tree().is_editor_hint():
	    		road_node.set_owner(get_tree().get_edited_scene_root())
	else:
		print("We already have a segment")
		var node = get_node("Road_instance"+String(index))
		var end = node.get_child(0).get_child(0).relative_end
		print("Location is " + String(node.get_translation()) + " end is " + String(end))
#		
#		
tool

extends Position3D

# class member variables go here, for example:
export(int) var numSegments = 2

#elements we're using
var road
var road_left
var road_straight

func _ready():
	# Called every time the node is added to the scene.
	road = preload("res://roads/road_segment.tscn")
	road_left = preload("res://roads/road_segment_left.tscn")
	road_straight = preload("res://roads/road_segment_straight.tscn")
	
	# Initialization here
	for index in range (numSegments):
			placeRoad(index)
	
	
	pass

func get_prev_segment(index):
	if has_node("Road_instance"+String(index-1)):
		return get_node("Road_instance"+String(index-1))
	
	#handle the fact that the straight needs a spatial parent
	if has_node("Spatial/Road_instance"+String(index-1)):
		return get_node("Spatial/Road_instance"+String(index-1))
		
func setupCurvedRoad(index, left, fit):
	if (left):
		var road_node_left = road_left.instance()
		road_node_left.set_name("Road_instance" + String(index))
		if (fit):
			road_node_left.get_child(0).get_child(0).start_angle = 30
			road_node_left.get_child(0).get_child(0).end_angle = 90
			print("Set angle to " + String(road_node_left.get_child(0).get_child(0).end_angle))
		add_child(road_node_left)
		return road_node_left
	else:
		var road_node_right = road.instance()
		road_node_right.set_name("Road_instance" + String(index))
		add_child(road_node_right)
		return road_node_right

func setupStraightRoad(index):
	var road_node = road_straight.instance()
	road_node.set_name("Road_instance" + String(index))
	
	var spatial = Spatial.new()
	spatial.set_name("Spatial")
	add_child(spatial)
	spatial.add_child(road_node)
	return road_node
	
func placeRoad(index):
	if (not has_node("Road_instance"+String(index))):
		var road_node
			
		if (index == 0):
			road_node = setupStraightRoad(index)
			#arrays were for debugging
			#positions.push_back(road_node.get_translation())
			#ends.push_back(road_node.get_child(0).get_child(0).relative_end)
		else:
			if (index % 2 > 0): ##odd
				var prev = get_prev_segment(index)
				if (prev != null):
					#handle the first segment being a straight (i.e. our index is 1)
					if (index == 1):
						print("Previous segment is " + prev.get_name())
						var prev_loc = prev.get_translation()
						#straights don't have children nodes because they don't need 'em
						#this is positive!!!
						var end_loc = prev.relative_end
						var loc = prev_loc + end_loc - Vector3(0,0,1)
						
						print("Location is " + String(loc))
						road_node = setupCurvedRoad(index, true, true)
						road_node.set_translation(loc)
						
					else:
						print("Previous segment is " + prev.get_name())
						var prev_loc = prev.get_translation()
						var end_loc = prev.get_child(0).get_child(0).relative_end
						var loc = prev_loc + end_loc
						if prev_loc != Vector3(0,0,0):
							loc = Vector3(prev_loc.x-end_loc.x, 0, prev_loc.z-end_loc.z)
						#print("Previous location is " + String(prev_loc))
						
						print("Location is " + String(loc))
						road_node = setupCurvedRoad(index, true)
						if prev_loc != Vector3(0,0,0):
							road_node.set_translation(loc)
						else:
							road_node.set_translation(-loc)
						#positions.push_back(road_node.get_translation())
						#ends.push_back(road_node.get_child(0).get_child(0).relative_end)
				else:
					print("No previous segment found")
			else: #even
				var prev = get_prev_segment(index)
				if (prev != null):
					print("Previous segment is " + prev.get_name())
					var prev_loc = prev.get_translation()
					#var prev_loc = positions[index-1]
					#var end_loc = ends[index-1]
					var end_loc = prev.get_child(0).get_child(0).relative_end
					var loc = prev_loc + end_loc
					#var loc = Vector3(prev_loc.x + end_loc.x, prev_loc.y + end_loc.y, prev_loc.z+end_loc.z)
					#print("End of previous location is " + String(prev.get_child(0).get_child(0).relative_end))
					#print("Previous segment location is " + String(prev_loc))
					print("Location is " + String(loc))
					
					road_node = road.instance()
					road_node.set_name("Road_instance" + String(index))
					add_child(road_node)
					
					#road_node = setupRoad(index, false)
					road_node.set_translation(loc)
					#positions.push_back(road_node.get_translation())
					#ends.push_back(road_node.get_child(0).get_child(0).relative_end)
				else:
					print("No previous segment found")
	else:
		print("We already have a segment")
		var node = get_node("Road_instance"+String(index))
		#var end = node.get_child(0).get_child(0).relative_end
		#print("Location is " + String(node.get_translation()) + " end is " + String(end))
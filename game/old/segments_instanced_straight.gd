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
	
	#call_deferred("navMesh")
	
	#pass

# utility functions
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
			road_node_left.get_child(0).get_child(0).start_angle = 90
			road_node_left.get_child(0).get_child(0).end_angle = 150 # 90+60; 90-30 = 60
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
			road_node.updateGlobalVerts()
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
						var loc = prev_loc + end_loc #- Vector3(0,0,1)
						
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
		
# nav mesh
func fitNavMesh(straight, straight_ind, straight_ind2, curve, curve_ind, curve_ind2, left):
	print("Fitting navmesh " + curve.get_parent().get_parent().get_name() + " "+ str(curve_ind) + ", " + str(curve_ind2) + " to " + straight.get_name() + " " + str(straight_ind) + ", " + str(straight_ind2)) 
	if (straight != null and straight.global_vertices != null and straight.global_vertices_alt != null):
		var target1 = straight.global_vertices[straight_ind]
		var target2 = straight.global_vertices[straight_ind2]
		#print("Loaded road: target 1 is " + String(target1) + " target 2 is " + String(target2))
		var target3 = straight.global_vertices_alt[straight_ind]
		var target4 = straight.global_vertices_alt[straight_ind2]
		
		# move the vertices to fit earlier straight
		var pos1 = curve.global_to_local_vert(target1)
#		#print("Local position of target 1 is: " + String(pos1))
		var pos2 = curve.global_to_local_vert(target2)
#		#print("Local position of target 2 is: " + String(pos2))
		
		var pos3 = curve.global_to_local_vert(target3)
		var pos4 = curve.global_to_local_vert(target4)
		
		# right lane on turn right
		curve.move_key_navi_vertices(curve_ind, pos3, curve_ind2, pos4)
		#print("New vertices from loaded instancer, are : " + String(curved.nav_vertices[curved.nav_vertices.size()-2]) + " " + String(curved.nav_vertices[curved.nav_vertices.size()-1]))
#		
		# this is left lane on turn right!!!
		curve.move_key_nav2_vertices(curve_ind, pos2, curve_ind2, pos1)

#		#create navmesh
		if left:
			#print("Creating navmesh for left turn")
			curve.navMesh(curve.nav_vertices, true)
			#create other lane
			curve.navMesh(curve.nav_vertices2, false)
		else:
			curve.navMesh(curve.nav_vertices, false)
			#create other lane
			curve.navMesh(curve.nav_vertices2, true)
			
func navMesh():
	#move the vertices so that the curve fits the straight
	var straight = get_node("Spatial/Road_instance0")
	var curved = get_node("Road_instance1").get_child(0).get_child(0)
	if curved != null:
		fitNavMesh(straight, 2, 3, curved, curved.nav_vertices.size()-2, curved.nav_vertices.size()-1, true)

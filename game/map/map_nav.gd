tool
extends Spatial

var ast # for BFS
var nav # for actual navigation
var path_look = {} # calculated paths

var flip_mat = preload("res://assets/car/car_red.tres")
var test_mat = preload("res://assets/car/car_blue.tres")
var test2_mat = preload("res://assets/car/car_black.tres")

# used all over the code
var mult

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Generic function	
func setup(mul, samples, real_edges):
	# set the variable
	mult = mul
	
	# call the functions
	setup_neighbors(samples, real_edges)
	var marker_data = spawn_markers(samples, real_edges)
	setup_map_nav(samples, real_edges)
	setup_markers(marker_data)

#-------------------------
# Distance map

func setup_neighbors(samples, edges):
	# we'll use AStar to have an easy map of neighbors
	ast = AStar.new()
	for i in range(0,samples.size()-1):
		ast.add_point(i, Vector3(samples[i][0]*mult, 0, samples[i][1]*mult))

	for i in range(0, edges.size()):
		var ed = edges[i]
		ast.connect_points(ed[0], ed[1])

# yes it could be more efficient I guess
func bfs_distances(start):
	# keep track of all visited nodes
	#var explored = []
	var distance = {}
	distance[start] = 0

	# keep track of nodes to be checked
	var queue = [start]

	# keep looping until there are nodes still to be checked
	while queue:
		# pop shallowest node (first node) from queue
		var node = queue.pop_front()
		#print("Visiting... " + str(node))

		var neighbours = ast.get_point_connections(node)
		# add neighbours of node to queue
		for neighbour in neighbours:
			# if not visited
			#if not explored.has(neighbour):
			if not distance.has(neighbour):
				queue.append(neighbour)
				distance[neighbour] = 1 + distance[node]


	return distance

func spawn_marker(samples, spots, mark, _name, limit=2):
	#print("Spawning @ spots: " + str(spots))
	# random choice of a connected (!) intersection to spawn at
	var sel = randi() % spots.size()
	var id = spots[sel]
	#print("Selected spot: " + str(id))
	var p = samples[id]
	
	var marker = mark.instance()
	#marker.set_name(_name)
	marker.set_translation(Vector3(p[0]*mult, 0, p[1]*mult))

	# create a distance map from our intersection
	# because the spots map can have different id from the samples
	var m_id = samples.find(p)
	var distance_map = bfs_distances(m_id)
	print(str(distance_map))
	
	#print("Keys: " + str(distance_map.keys()))
	#print("Values: " + str(distance_map.values()))

	# pick a target
	var possible_targets = []
	for n in distance_map.keys():
		var v = distance_map[n]
		if v >= 1 and v < limit:
			Logger.mapgen_print("Possible target id: " + str(n))
			possible_targets.append(n)

	var t_id = null
	if possible_targets.size() < 1:
		return
		
	if possible_targets.size() > 1:
		# pick randomly
		t_id = possible_targets[randi() % possible_targets.size()]
	else:
		t_id = possible_targets[0]

	Logger.mapgen_print("Target id: " + str(t_id))

	marker.target = Vector3(samples[t_id][0]*mult, 0, samples[t_id][1]*mult)
	Logger.mapgen_print("Marker target is " + str(marker.target))

	# add marker to map itself
	get_parent().add_child(marker)
	# neither : nor @ works here, so I had to use something else
	marker.set_name(_name + ">" + str(id)+"-"+str(t_id))
	
	# remove from list of possible spots
	spots.remove(sel) # this works by id not value!
	
	if _name == "race_marker":
		#print("Set marker ai data")
		marker.ai_data = [m_id, t_id, to_global(marker.target)]

	return [m_id, t_id]

func spawn_markers(samples, real_edges):
	var spots = []

	var mark = preload("res://objects/marker.tscn")
	var sp_mark = preload("res://objects/speed_marker.tscn")
	var race_mark = preload("res://objects/race_marker.tscn")

	# random choice of an intersection to spawn at
	
	# ensure the spots considered are actually connected 
	for i in range(samples.size()-1):
		for e in real_edges:
			if e.x == i or e.y == i:
				spots.append(i)
				break #the first find should be enough
	
	print("Spots list: " + str(spots))
	
	# trick to copy the array
	#spots = [] + samples
	#spots.pop_back() # we don't want the last entry
	
	var num_inters = spots.size()
	var sel = randi() % num_inters
	var id = spots[sel]
	#print(str(id))
	# id equals intersection number
	var p = samples[id]

	var sp_marker = sp_mark.instance()
	sp_marker.set_translation(Vector3(p[0]*mult, 0, p[1]*mult))
	sp_marker.set_name("speed_marker"+">" + str(id))
	# add marker to the map itself
	get_parent().add_child(sp_marker)

	# remove from list of possible spots
	spots.remove(sel) # this works by id not value, unlike Python!

	var marker_data = spawn_marker(samples, spots, mark, "tt_marker")
	print("Marker data: " + str(marker_data))
	
	var mark_data = spawn_marker(samples, spots, race_mark, "race_marker")
	marker_data.append(mark_data[0])
	marker_data.append(mark_data[1])
	
	print("Marker data: " + str(marker_data))
	
	return marker_data

# -----------------------------------
	
func setup_map_nav(samples, real_edges):
	var roads_start_id = 3+samples.size()-1 # 3 helper nodes + intersections for samples
	
	nav = AStar.new()
	var pts = []
	var begin_id = 0
	#var path_data = []
	path_look = {}

	#print("Setting up nav for: ", real_edges)
	#print("Size: ", real_edges.size())

	# FIXME: potential problems if too many roads are not created (not in real_edges)
	for i in range(roads_start_id, roads_start_id+ real_edges.size()): #4):
		#print("Index: " + str(i))
		#print("Begin: " + str(begin_id))
		var data = setup_nav_astar(pts, i, begin_id)
		#print('Begin: ' + str(begin_id) + " end: " + str(data[0]) + " inters: " + str(data[1]))
		#path_data.append([data[1], [begin_id, data[0]]])
		# if we had something to set up
		if data:
			path_look[data[2]] = [begin_id, data[0]]
			# just in case, map inverse too
			path_look[[data[2][1], data[2][0]]] = [data[0], begin_id]

			# increment begin_id
			begin_id = data[1]+1

	print("Path_look: " + str(path_look))

func setup_markers(marker_data):
	# test the nav
	if marker_data != null:
		#var marker = get_node("tt_marker")
		var marker = get_parent().get_marker("tt_marker")
	#print(marker.get_translation())
		var tg = marker.target
	#print("tg : " + str(tg))

#	print("Marker intersection id" + str(marker_data[0]) + " tg id" + str(marker_data[1]))
		var int_path = ast.get_id_path(marker_data[0], marker_data[1])
		print("Intersections path: " + str(int_path))

#	# test (get path_look entry at id x)
#	var test = path_look[path_look.keys()[5]]
#	print("Test: " + str(test))
#	var nav_path = nav.get_point_path(test[0], test[1])
#	#print("Nav path: " + str(nav_path))
#	# so that we can see
#	marker.raceline = nav_path

		#paranoia
		var nav_path = PoolVector3Array()
		if [int_path[0], int_path[1]] in path_look:
			#print("First pair: " + str(int_path[0]) + "," + str(int_path[1]))			
			var lookup_path = path_look[[int_path[0], int_path[1]]]
			#print("Lookup path pt1: " + str(lookup_path))
			nav_path = nav.get_point_path(lookup_path[0], lookup_path[1])
			#print("Nav path: " + str(nav_path))
			# so that the player can see
			#marker.raceline = nav_path
		var nav_path2 = PoolVector3Array()
		var nav_path3 = PoolVector3Array()
		if int_path.size() > 2 and [int_path[1], int_path[2]] in path_look:
			#print("Second pair: " + str(int_path[1]) + "," + str(int_path[2]))
			var lookup_path = path_look[[int_path[1], int_path[2]]]
			#print("Lookup path pt2: " + str(lookup_path))
			nav_path2 = nav.get_point_path(lookup_path[0], lookup_path[1])
			#print("Nav path pt2 : " + str(nav_path2))
	
		if int_path.size() > 3:
			if [int_path[2], int_path[3]] in path_look:
				#print("Third pair: " + str(int_path[2]) + "," + str(int_path[3]))
				var lookup_path = path_look[[int_path[2], int_path[3]]]
				#print("Lookup path pt3: " + str(lookup_path))
				nav_path3 = nav.get_point_path(lookup_path[0], lookup_path[1])
			#print("Nav path pt3: " + str(nav_path3))
	
		# display the whole path
		marker.raceline = nav_path + nav_path2 + nav_path3
		#print("TT raceline: ", marker.raceline)
		
		# the same for race marker	
		marker = get_parent().get_marker("race_marker")
		#marker = get_node("race_marker")
	#print(marker.get_translation())
		tg = marker.target
	#print("tg : " + str(tg))

#	print("Marker intersection id" + str(marker_data[0]) + " tg id" + str(marker_data[1]))
		int_path = ast.get_id_path(marker_data[2], marker_data[3])
		print("Intersections path: " + str(int_path))

		# TODO: factor out into a function
		#paranoia
		nav_path = PoolVector3Array()
		if [int_path[0], int_path[1]] in path_look:
			#print("First pair: " + str(int_path[0]) + "," + str(int_path[1]))			
			var lookup_path = path_look[[int_path[0], int_path[1]]]
			#print("Lookup path pt1: " + str(lookup_path))
			nav_path = nav.get_point_path(lookup_path[0], lookup_path[1])
			#print("Nav path: " + str(nav_path))
			# so that the player can see
			#marker.raceline = nav_path
		nav_path2 = PoolVector3Array()
		nav_path3 = PoolVector3Array()
		if int_path.size() > 2 and [int_path[1], int_path[2]] in path_look:
			#print("Second pair: " + str(int_path[1]) + "," + str(int_path[2]))
			var lookup_path = path_look[[int_path[1], int_path[2]]]
			#print("Lookup path pt2: " + str(lookup_path))
			nav_path2 = nav.get_point_path(lookup_path[0], lookup_path[1])
			#print("Nav path pt2 : " + str(nav_path2))
	
			
		if int_path.size() > 3:
			if [int_path[2], int_path[3]] in path_look:
				#print("Third pair: " + str(int_path[2]) + "," + str(int_path[3]))
				var lookup_path = path_look[[int_path[2], int_path[3]]]
				#print("Lookup path pt3: " + str(lookup_path))
				nav_path3 = nav.get_point_path(lookup_path[0], lookup_path[1])
			#print("Nav path pt3: " + str(nav_path3))
	
		# display the whole path
		marker.raceline = nav_path + nav_path2 + nav_path3
		#print("Race raceline: " + str(marker.raceline))
	

# this is being used by racelines, therefore it can't be simplified further
func setup_nav_astar(pts, i, begin_id):
	#print("Index: " + str(i) + " " + get_parent().get_child(i).get_name())
	#print(get_parent().get_child(i).get_name())
	# catch any errors
	if i >= get_parent().get_child_count():
		Logger.error_print("No child at index : " + str(i))
		return

	# extract intersection numbers
	var ret = []
	var strs = get_parent().get_child(i).get_name().split("-")
	# convert to int
	ret.append(int(strs[0].lstrip("Road ")))
	ret.append(int(strs[1]))
	#print("Ret: " + str(ret))

	# paranoia
	if not get_parent().get_child(i).has_node("Road_instance0"):
		return
	if not get_parent().get_child(i).has_node("Road_instance1"):
		return

	var turn1 = get_parent().get_child(i).get_node("Road_instance0").get_child(0).get_child(0)
	var turn2 = get_parent().get_child(i).get_node("Road_instance1").get_child(0).get_child(0)

	#print("Straight positions: " + str(get_child(i).get_node("Spatial0").get_child(0).positions))
	#print("Turn 1 positions: " + str(turn1.positions))
	#print("Turn 1 center points: " + str(turn1.points_center))
	#print("Turn 2 positions: " + str(turn2.positions))

	#print("Turn 1 global pos: " + str(turn1.get_global_transform().origin))
	#print("Turn 2 global pos: " + str(turn2.get_global_transform().origin))

	#debug_cube(to_local(Vector3(turn1.get_global_transform().origin.x, 3, turn1.get_global_transform().origin.z)))
	#debug_cube(to_local(Vector3(turn2.get_global_transform().origin.x, 3, turn2.get_global_transform().origin.z)))

	# from local to global
	for i in range(0,turn1.points_center.size()):
		# this seemingly small change cuts down on the number of points by half!! 
		# yay me for noticing positions has double the number of points
		#var p = turn1.positions[i]
		var c = turn1.points_center[i]
		var p = Vector3(c.x, turn1.road_height, c.y)
		pts.append(turn1.to_global(p))

	#print(pts)
	for i in range(0,turn2.points_center.size()):
		#var p = turn2.positions[i]
		var c = turn2.points_center[i]
		var p = Vector3(c.x, turn1.road_height, c.y)
		pts.append(turn2.to_global(p))

	#print("All points: " + str(pts.size()))
	#print("With turn2: " + str(pts))

	# add pts to nav (road-level AStar)
	for i in range(pts.size()):
		nav.add_point(i, pts[i])

	#print(nav.get_points())

	# connect the points
	var turn1_end = begin_id + turn1.points_center.size()-1
	# because of i+1
	for i in range(begin_id, turn1_end):
		nav.connect_points(i, i+1)

	var turn2_end = begin_id + turn1.points_center.size()+turn2.points_center.size()-1
	for i in range(begin_id + turn1.points_center.size(), turn2_end):
		nav.connect_points(i, i+1)

	# because turn 2 is inverted
	# connect the endpoints
	nav.connect_points(turn1_end, turn2_end)
	# full path
	var endpoint_id = begin_id + turn1.points_center.size() # beginning of turn2

	var last_id = turn2_end

	# turn1
	#var endpoint_id = turn1_end
	#print("Endpoint id " + str(endpoint_id))
	#print("Test: " + str(nav.get_point_path(begin_id, endpoint_id)))
	# turn2 only
	#print("Test 2: " + str(nav.get_point_path(begin_id + turn1.positions.size(), turn2_end)))

	# road's end, list end, intersection numbers
	return [endpoint_id, last_id, ret]

# this is governed by map not AI (so that lanes are picked consistently depending on direction of travel)
func get_lane(road, int_path, flip, left_side):
	var pts = []
	# paranoia
	if not road.has_node("Road_instance0"):
		return
	if not road.has_node("Road_instance1"):
		return

	# which direction are we going?
	# shortcut (we know map has 3 nodes before intersections)
	var src = get_parent().get_child(int_path[0]+3)
	var dst = get_parent().get_child(int_path[1]+3)
	var rel_pos = src.get_global_transform().xform_inv(dst.get_global_transform().origin)
	# same as in connect_intersections.gd
	# by convention, y comes first
	var angle = atan2(rel_pos.z, rel_pos.x)
	
	# pick lane depending on relative direction (quadrant)
	# "flip" (set by AI earlier) means we are going the other way to the way the map was designed
	
	# NE (quadrant 1)
	if rel_pos.x > 0 and rel_pos.z < 0:
		if flip:
			left_side = true
		else:
			left_side = false
	# NW (quadrant 2)
	if rel_pos.x < 0 and rel_pos.z > 0:
		if flip:
			left_side = false
		else:
			left_side = true
	# SE (quadrant 3)
	if rel_pos.x > 0 and rel_pos.z > 0:
		if not flip:
			left_side = true
		else:
			left_side = false
	# SW (quadrant 4)
	if rel_pos.x < 0 and rel_pos.z < 0:
		if flip: 
			left_side = true
		else:
			left_side = false
	
			
	print(road.get_name(), " rel pos road start-end: ", rel_pos, " angle: ", angle, " ", rad2deg(angle), " deg quadrant ", get_quadrant(rel_pos), " flip: ", flip, " left: ", left_side)

	# this part actually gets A* points
	var turn1 = road.get_node("Road_instance0").get_child(0).get_child(0)
	var turn2 = road.get_node("Road_instance1").get_child(0).get_child(0)
	
	var lane_lists = []
	# side
	if left_side:
		if not flip:
			# account for roads going almost straight (the checks here are ad hoc)
			if angle < 0.4 or (turn1.start_angle > 250 and turn2.start_angle > 300):
				lane_lists = [turn1.points_inner_nav, turn2.points_inner_nav]
			else:
				lane_lists = [turn1.points_inner_nav, turn2.points_outer_nav]
		else:
			# account for roads going almost straight
			if angle < -PI+0.4 or (turn1.start_angle > 250 and turn2.start_angle > 300):
				lane_lists = [turn1.points_outer_nav, turn2.points_outer_nav]	
			else:
				lane_lists = [turn1.points_outer_nav, turn2.points_inner_nav]
	# right side
	else:
		if not flip:
			# account for roads going almost straight (the checks here are ad hoc)
			if angle > -0.79 and angle < -0.1:
				lane_lists = [turn1.points_outer_nav, turn2.points_outer_nav]
			else:
				lane_lists = [turn1.points_outer_nav, turn2.points_inner_nav]
		else:
			# account for roads going almost straight
			if angle > 2.35 and angle < 3.04:
				lane_lists = [turn1.points_inner_nav, turn2.points_inner_nav]
			else:
				lane_lists = [turn1.points_inner_nav, turn2.points_outer_nav]

	# keeping 'em global for consistency with the A* centerline
	# from local to global
	#print("Turn size: ", lane_lists[0].size())
	
	for i in range(0,lane_lists[0].size()):
		var c = lane_lists[0][i]
		var p = Vector3(c.x, turn1.road_height, c.y)
		pts.append(turn1.to_global(p))

	#print(pts)
	#print("Points: ", pts.size()) # 33
	
	# because turn 2 is inverted
	for i in range(lane_lists[1].size()-1, 0, -1):
		var c = lane_lists[1][i]
		var p = Vector3(c.x, turn1.road_height, c.y)
		pts.append(turn2.to_global(p))
	#print("Points with turn 2: ", pts.size()) # 65 = 33+32

	if flip:
		pts.invert()
		
	var midpoint = get_lane_midpoint(pts, flip)
	pts.append(midpoint)

	# left and flip are used mostly for debugging
	return [pts, left_side, flip]

func get_lane_midpoint(nav_path, flip):
	# B-A - vector from A to B
	var midpoint = nav_path[32]+(nav_path[33]-nav_path[32])/2
	if flip:
		# why the difference by 1?
		midpoint = nav_path[31]+(nav_path[32]-nav_path[31])/2
	return midpoint

func get_quadrant(rel_pos):
	# NE (quadrant 1)
	if rel_pos.x > 0 and rel_pos.z < 0:
		return "NE"
	# NW (quadrant 2)
	if rel_pos.x < 0 and rel_pos.z > 0:
		return "NW"
	# SE (quadrant 3)
	if rel_pos.x > 0 and rel_pos.z > 0:
		return "SE"
	# SW (quadrant 4)
	if rel_pos.x < 0 and rel_pos.z < 0:
		return "SW"

# called from the outside, eg. by AI when pathing
func get_paths(id, exclude=-1):
	print("Get path for id: " + str(id) + ", exclude: " + str(exclude))
	#print("Path_look: " + str(self.path_look))

	var paths = []
	for p in self.path_look:
	#for i in range(self.path_look.size()):
	#	var p = self.path_look.keys()[i]
		#print("Path considered: " + str(p))
		if p[0] == id:
			paths.append(p)

	print("Paths for id : " + str(id) + " " + str(paths))

	# if only one path, just pick it
	if paths.size() == 1:
		return paths

	# remove excluded paths
	if exclude != -1:
		for p in paths:
			if p[1] == exclude:
				paths.remove(paths.find(p))
	print("Possible paths for id : " + str(id) + " " + str(paths))
	return paths

func get_path_look(id, exclude=-1):
	var int_path = null
	var paths = get_paths(id, exclude)
	
	# if only one path after we removed exclusions, just pick it
	if paths.size() == 1:
		return paths[0]
		
	# randomize selection
	randomize()
	id = randi() % paths.size()
	int_path = paths[id]
				
	return int_path

func debug_lanes(type=1):
	var map = get_parent()
	for p in path_look:
		#print(str(p))
		
		# get road from ids
		var rd_name = "Road "+str(p[0])+"-"+str(p[1])
		var flip = false
	
		if not map.has_node(rd_name):
			# skip
			#continue
#			# try the other way?
			rd_name = "Road " + str(p[1])+"-"+str(p[0])
			flip = true
		#print("Road name: " + rd_name)
		var road = map.get_node(rd_name)
		
		# only interested in some lanes
		# which direction are we going?
		# shortcut (we know map has 3 nodes before intersections)
#		var src = map.get_child(p[0]+3)
#		var dst = map.get_child(p[1]+3)
#		var rel_pos = src.get_global_transform().xform_inv(dst.get_global_transform().origin)
#		if rel_pos.x > 0 and rel_pos.z > 0:
		#if flip:
		var nav_data = []
		var nav_path
		if type == 0 or type == 2: # normal or both
			# normal direction
			nav_data = map.get_node("nav").get_lane(road, p, flip, true)
			nav_path = nav_data[0]
			
			# set flags
			var flag = ""
			if flip:
				if not nav_data[1]:
					flag = "flip"
				else:
					flag = "left_flip"
			
			else:
				flag = "left_flip"
				if nav_data[1]:
					flag = "left"
					
			# those points are global (see line 442)
			for pt in nav_path:
				debug_cube(to_local(pt), flag)
				
		if type == 1 or type == 2: # other or both
			# test other case	
			nav_data = map.get_node("nav").get_lane(road, p, not flip, true)
			nav_path = nav_data[0]
			
		

			# set flags
			var flag = ""
			if flip:
				if not nav_data[1]:
					flag = "flip"
				else:
					flag = "left_flip"
			
			else:
				if nav_data[1]:
					flag = "left"
					
			# those points are global (see line 442)
			for pt in nav_path:
				debug_cube(to_local(pt), flag)
			
# ------------------------------------
# it could probably be done at AI level, but this way it's more general, maybe for the player
func intersection_arc(car, closest, nav_path):
	# transform them to intersection space for easier calc
	var p1_ = closest.to_local(car.get_global_transform().origin)
	var p2_ = closest.to_local(nav_path[0])

	# dummy out y since we are not going to care
	var p1 = Vector2(p1_.x, p1_.z)
	var p2 = Vector2(p2_.x, p2_.z)
	#midpoint
	var p4 = (p2+p1)/2
	#debug_cube(to_local(closest.get_global_transform().origin+Vector3(p4.x, 0.01, p4.y)), "flip")
	
	var p3 = p4.clamped(3)
	debug_cube(to_local(closest.get_global_transform().origin+Vector3(p3.x, 0.01, p3.y)), "flip")
	
	# test
	#var ccw = is_arc_clockwise(p1, p3, p2)
	#print("Arc clockwise? - ", ccw)
	
	# arc from 3 points
	# https://stackoverflow.com/a/53318286
	# a = p1, b = p3, c = p2; s1, s2 = m1, m2
	var d1 = Vector2(p3.y-p1.y, p1.x-p3.x)
	var d2 = Vector2(p2.y-p1.y, p1.x-p2.x)
	var k = d2.x * d1.y - d2.y * d1.x
	
	# paranoia
	if k == 0:
		return []
	
	
	# midpoints of two chords
	var m1 = (p3+p1)/2
	var m2 = (p2+p1)/2
	
	var l = d1.x * (m2.y - m1.y) - d1.y * (m2.x - m1.x)
	# slope of something?
	var m = l / k
	var center = Vector2(m2.x + m * d2.x, m2.y + m * d2.y)
	
	var radius = center.distance_to(p1)
	#var dx = center.x - a.x
	#var dy = center.y - a.y
	#let radius = sqrt(dx * dx + dy * dy)
	
	print("radius: ", radius, ", center: ", center)
	
	#var p4_loc = Vector2(0,0).distance_to(p4)
	
	# sagitta (the height of the arc, or how much it "bulges")
#	var s_len = (p4-p3).length()
#
#	# paranoia!
#	if s_len == 0:
#		s_len = 0.01
#
#	print(" right: ", ccw, " : p1 (car) ", p1, " p2 ", p2, " p4 ", p4, " s len ", s_len)
#
#	# ref: https://www.afralisp.net/archive/lisp/Bulges1.htm
#	# sagitta is always perpendicular to p1-p2
#	#B-A: A->B 
#	var half = p4-p1
#	var perp = p4 + half.tangent() # perpendicular vector
#	var n = (perp-p4).normalized() # unit vector
#	#print("unit vec: ", n)
#
#	#var s_end = p4-n*s_len #P3
#	#debug_cube(to_local(closest.get_global_transform().origin+Vector3(s_end.x, 0.01, s_end.y)), true)
#	#print("Sagitta endpoint: ", s_end)
#
#	# sagitta (p3-p4) forms a right triangle with either of p1-p4 or p2-p4 (half of chord)
#	# so tan(angle at p1 or p2) = sagitta divided by either p1-p4 or p2-p4
#	# hence atan sagitta / p1-p4 is the angle epsilon 
#
#	# tangent of epsilon (epsilon is the arc angle divided by 4)
#	#var ta = s/(p4-p1)
#	var half_len = half.length()
#	#var eps = atan(s_len/half_len)
#	# half of chord^2+sagitta^2 divided by 2*sagitta
#	#var radius = (pow(half_len, 2)+pow(s_len,2))/2*s_len
#
#	# radius = h + s_len AND C p4 p2 is a right triangle
#	#https://math.stackexchange.com/a/491816
#	# h=u, t is half_len, b is sagitta length
#	var h = (pow(half_len,2) - pow(s_len,2))/(2*s_len)
#
#	#https://math.stackexchange.com/a/87374
#	#var h = sqrt(pow(radius,2) - pow(half_len*2, 2)/4)
#
#	# radius from sagitta and chord
#	# https://math.stackexchange.com/a/2135602
#	# radius = s_len/2+chord^2/2*s_len
#	#var radius = s_len/2+pow(half_len*2,2)/(2*s_len)
#	#var h = radius - s_len
#
#	#if h < 0:
#	#	print("Error!")
#
#	var radius = h + s_len	
	#print("h: ", h, " radius ", radius, " s ", s_len)

	# now we can finally find the center
	#var center = p4+h*n
	
	var gloc_c = closest.get_global_transform().origin + Vector3(center.x, 0.01, center.y)
	#debug_cube(to_local(gloc_c), "flip")
	#print("Center: ", center)

	# the point to which 0 degrees corresponds
	var angle0 = center+Vector2(radius,0)
	#print("Angle0: ", angle0)
	#debug_cube(to_local(closest.get_global_transform().origin + Vector3(angle0.x, 0.01, angle0.y)), "flip")
	
	# get two angles/arcs
	var angles = get_arc_angle(center, p1, p3, angle0)
	var points_arc1 = get_circle_arc(center, radius, angles[0], angles[1], true, 16)
	
	angles = get_arc_angle(center, p3, p2, angle0)
	var points_arc2 = get_circle_arc(center, radius, angles[0], angles[1], true, 16)
	
	var points_arc = points_arc1 + points_arc2
	
	# debug
	#print("Intersection arc for inters: ", closest.get_global_transform().origin)
	
	var arcs = []
	for i in range(points_arc.size()):
		var gloc = Vector3(points_arc[i].x, 0.01, points_arc[i].y)+closest.get_global_transform().origin
		arcs.append(gloc)
		#debug_cube(to_local(gloc), "left_flip")
	
	
	#var midpoint = Vector3(points_arc[16].x, 0.01, points_arc[16].x)
	#var pos = closest.get_global_transform().origin+midpoint
		
	return arcs

# https://stackoverflow.com/a/63566113
func is_arc_clockwise(p1, p2, p3):
	var se = p3-p2
	var sm = p1-p2
	var cp = se.cross(sm)
	return cp > 0
	
	
# calculated arc is in respect to X axis
func get_arc_angle(center_point, start_point, end_point, angle0, verbose=false):
	var angles = []
	
	# angle between line from center point to angle0 and from center point to start point
	var angle1 = rad2deg((angle0-center_point).angle_to(start_point-center_point))
	
	if angle1 < 0:
		angle1 = 360+angle1
		#print("Angle 1 " + str(angle))
	
	#angles.append(angle)
	#Logger.mapgen_print("Angle 1 " + str(angle1))
	# equivalent angle for the end point
	var angle2 = rad2deg((angle0-center_point).angle_to(end_point-center_point))
	
	if angle2 < 0:
		angle2 = 360+angle2
		#print("Angle 2 " + str(angle))
	
	#Logger.mapgen_print("Angle 1 " + str(angle1) + ", angle 2 " + str(angle2))
	#angles.append(angle)
	
	var arc = angle1-angle2
	
	if verbose:
		print("Angle 1 " + str(angle1) + ", angle 2 " + str(angle2) + " = arc angle " + str(arc))
		
	if arc > 190:
		if verbose:
			print("Too big arc " + str(angle1) + " , " + str(angle2))
		angle2 = angle2+360
	if arc < -190:
		if verbose:
			print("Too big arc " + str(angle1) + " , " + str(angle2))
		angle1 = angle1+360
		
	angles = [angle1, angle2]
	
	return angles

# from maths
func get_circle_arc( center, radius, angle_from, angle_to, right, nb_points=32):
	#var nb_points = 32
	var points_arc = PoolVector2Array()

	for i in range(nb_points+1):
		if right:
			var angle_point = angle_from + i*(angle_to-angle_from)/nb_points #- 90
			var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
			points_arc.push_back( point )
		else:
			var angle_point = angle_from - i*(angle_to-angle_from)/nb_points #- 90
			var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
			points_arc.push_back( point )
	
	return points_arc		


func debug_cube(loc, flag=""):
	var mesh = CubeMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance.new()
	node.set_mesh(mesh)
	if flag == "flip":
		node.get_mesh().surface_set_material(0, flip_mat) #red
	if flag == "left_flip":
		node.get_mesh().surface_set_material(0, test_mat) # blue
	if flag == "left":
		node.get_mesh().surface_set_material(0, test2_mat) # black (because it's the counterpart to white, i.e. right)
	node.set_cast_shadows_setting(0)
	node.add_to_group("debug")
	add_child(node)
	node.set_translation(loc)
	# offset flipped a bit
	if flag == "flip" or flag == "left_flip":
		node.translate(Vector3(0.0, 0.2, 0.0))
	
func clear_cubes():
	for c in get_children():
		if c.is_in_group("debug") and c.is_class("MeshInstance"):
			c.queue_free()

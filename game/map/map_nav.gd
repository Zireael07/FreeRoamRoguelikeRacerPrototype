@tool
extends Node3D

# prime candidate for rewriting to something speedier in the future (also procedural_map.gd)

var ast # for intersection-level pathing
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
	# all the functions here care only about real edges
	setup_neighbors(samples, real_edges)
	var marker_data = spawn_markers(samples, real_edges)
	setup_map_nav(samples, real_edges)
	setup_markers(marker_data)
	# test
	#var A = get_adjacency_list(samples)
	#cycles = CycleFinder.new().get_cycles(A)

#-----------------------------------------------
# our graph is undirected (all roads/edges are bidirectional)
# BFS *can* find cycles in an undirected graph but DFS seems to be recommended
class CycleFinder:
	var cycles = [] # this lone thing is why we use an inner class
	
	# Function to mark the vertex with different colors for different cycles
	func _dfs_cycle(A, u, p, color, parents):
		# already (completely) visited vertex.
		if color[u] == "BLACK": #2
			return
			
		# seen vertex, but was not
		# completely visited -> cycle detected.
		# backtrack based on parents to
		# find the complete cycle.
		if color[u] == "GRAY": #1
			var cur = p
			#print("Cycle found, stumbled on ", u, " again from ", p, ".") 
			self.cycles.push_back([p])

			# backtrack the vertex which are
			# in the current cycle thats found
			while cur != u:
				cur = parents[cur]
				self.cycles[self.cycles.size()-1].append(cur)
				#print("Backtracking in cycle, id: ", cur)
			return
			
		parents[u] = p
		
		# partially visited.
		color[u] = "GRAY" #1
		
		# simple DFS on graph
		for v in A[u]:
			# if it has not been visited previously
			# skip links to parent
			if v == parents[u]:
				continue
			_dfs_cycle(A, v, u, color, parents)
			
		# completely visited.
		color[u] = "BLACK" #2

		# debug
		#print("DFS color: ",color)
		
	func get_cycles(A):
		# Initialize variables
		var color = []
		var parents = []
		#var mark = []
		#var cyclenumber = 0
		var num_edges = A.size()
		
		# 4.0 functions
		color.resize(num_edges)
		color.fill("WHITE")
		parents.resize(num_edges)
		parents.fill(-1)
			
		_dfs_cycle(A, 0, -1, color, parents)
		
		print("Cycles found: ", self.cycles)
		return self.cycles
		
	# function to find cycles through vert X
	func get_cycles_vert(A, id):
		# Initialize variables
		var color = []
		var parents = []
		var num_edges = A.size()
		
		# 4.0 functions
		color.resize(num_edges)
		color.fill("WHITE")
		parents.resize(num_edges)
		parents.fill(-1)
			
		_dfs_cycle(A, id, -1, color, parents)
		
		print("Cycles found for id: ", id, ", ", self.cycles)
		
		# check if id is in cycles
		self.cycles = self.cycles.filter(func(c): return id in c)
		
		print("Cycles post-filter: ", self.cycles)
		
		return self.cycles
		
# inner class ends here

func rotate_array(arr, n):
	#print("Rotating array ", arr,  " by ", n)
	var new_lis = []
	# store from n to end, then add 0 to n
	new_lis = arr.slice(n)+arr.slice(0,n)
	return new_lis

# ---------------------------------------------
# Distance map and related stuff
# because we don't have access to the graph structure underlying AStar :((
func get_adjacency_list(samples):
	var A = {} # adjacency list, i.e. neighbors for node v
	# quick and dirty adjacency list
	for i in range(0,samples.size()-1):
		# see l. 76 for use and l.54 for creation
		# takes id not vertex pos
		var neighbours = ast.get_point_connections(i)
		var node = samples[i]
		A[i] = neighbours
	print("Adjacency list: ", A)
	return A

# this creates an AStar map in which i always corresponds to sample's i
func setup_neighbors(samples, edges):
	# we'll use AStar to have an easy map of neighbors
	ast = AStar3D.new()
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
	
	var marker = mark.instantiate()
	#marker.set_name(_name)
	marker.set_position(Vector3(p[0]*mult, 0, p[1]*mult))

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
	spots.remove_at(sel) # this works by id not value!
	
	if _name == "race_marker":
		#print("Set marker ai data")
		marker.ai_data = [m_id, t_id, to_global(marker.target)]

	return [m_id, t_id]

func spawn_circuit_marker(samples, spots, mark):
	# random choice of a connected (!) intersection to spawn at
	var sel = randi() % spots.size()
	var id = spots[sel]
	#print("Selected spot: " + str(id))
	var p = samples[id]
	
	var marker = mark.instantiate()
	#marker.set_name(_name)
	marker.set_position(Vector3(p[0]*mult, 0, p[1]*mult))
	
	# find a cycle
	var A = get_adjacency_list(samples)
	var cycles = CycleFinder.new().get_cycles_vert(A, id)
	
	# for the marker to work properly, the cycle needs to START with our vert
	# so we rotate by the id
	print("Found cycle, ", cycles[0])
	var _id = cycles[0].find(id)
	var cycle = rotate_array(cycles[0], _id)
	
	print(cycle)
	# save cycle
	marker.cycle = cycle	
	marker.ai_data = [cycle]
	
	# add marker to map itself
	get_parent().add_child(marker)
	# neither : nor @ works here, so I had to use something else
	marker.set_name("circuit_marker" + ">" + str(id))
	
	# remove from list of possible spots
	spots.remove_at(sel) # this works by id not value!
	
	print("Spawned circuit marker @ ", id)
	
	return [id]

func spawn_markers(samples, real_edges):
	var spots = []

	var mark = preload("res://objects/marker.tscn")
	var sp_mark = preload("res://objects/speed_marker.tscn")
	var race_mark = preload("res://objects/race_marker.tscn")
	var circuit_mark = preload("res://objects/circuit_marker.tscn")

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

	var sp_marker = sp_mark.instantiate()
	sp_marker.set_position(Vector3(p[0]*mult, 0, p[1]*mult))
	sp_marker.set_name("speed_marker"+">" + str(id))
	# add marker to the map itself
	get_parent().add_child(sp_marker)

	# remove from list of possible spots
	spots.remove_at(sel) # this works by id not value, unlike Python!

	var marker_data = spawn_marker(samples, spots, mark, "tt_marker")
	print("Marker data: " + str(marker_data))
	
	var mark_data = spawn_marker(samples, spots, race_mark, "race_marker")
	marker_data.append(mark_data[0])
	marker_data.append(mark_data[1])
	
	print("Marker data: " + str(marker_data))
	
	var m_data = spawn_circuit_marker(samples, spots, circuit_mark)
	
	return marker_data

# -----------------------------------
# NOTE: this sets up the separate AStar graph structure, for lower-level pathing (on roads)		
func setup_map_nav(samples, real_edges):
	var roads_start_id = 3+samples.size()-1 # 3 helper nodes + intersections for samples
	
	nav = AStar3D.new()
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

# this is being used by racelines, therefore it can't be simplified further, needs to be many points
func setup_nav_astar(pts, idx, begin_id):
	#print("Index: " + str(i) + " " + get_parent().get_child(i).get_name())
	#print(get_parent().get_child(i).get_name())
	# catch any errors
	if idx >= get_parent().get_child_count():
		Logger.error_print("No child at index : " + str(idx))
		return

	# extract intersection numbers
	var ret = []
	var strs = String(get_parent().get_child(idx).get_name()).split("-")
	# convert to int
	ret.append((strs[0].lstrip("Road ").to_int()))
	ret.append((strs[1].to_int()))
	#print("Ret: " + str(ret))

	# paranoia
	if not get_parent().get_child(idx).has_node("Road_instance0"):
		return
	if not get_parent().get_child(idx).has_node("Road_instance1"):
		return

	var turn1 = get_parent().get_child(idx).get_node(^"Road_instance0").get_child(0).get_child(0)
	var turn2 = get_parent().get_child(idx).get_node(^"Road_instance1").get_child(0).get_child(0)

	#print("Straight positions: " + str(get_child(i).get_node(^"Spatial0").get_child(0).positions))
	#print("Turn 1 positions: " + str(turn1.positions))
	#print("Turn 1 center points: " + str(turn1.points_center))
	#print("Turn 2 positions: " + str(turn2.positions))

	#print("Turn 1 global pos: " + str(turn1.get_global_transform().origin))
	#print("Turn 2 global pos: " + str(turn2.get_global_transform().origin))

	#debug_cube(to_local(Vector3(turn1.get_global_transform().origin.x, 3, turn1.get_global_transform().origin.z)))
	#debug_cube(to_local(Vector3(turn2.get_global_transform().origin.x, 3, turn2.get_global_transform().origin.z)))

	# debug/setup ends here

	# from local to global
	# and from 2D to 3D because raceline is 3D
	for i in range(0,turn1.points_center.size()):
		# this seemingly small change cuts down on the number of points by half!! 
		# yay me for noticing positions has double the number of points
		#var p = turn1.positions[i]
		var c = turn1.points_center[i]
		var p = Vector3(c.x, turn1.road_height, c.y)
		pts.append(turn1.to_global(p))

	#print(pts) # 33
	for i in range(0,turn2.points_center.size()):
		#var p = turn2.positions[i]
		var c = turn2.points_center[i]
		var p = Vector3(c.x, turn1.road_height, c.y)
		pts.append(turn2.to_global(p))

	#print("All points: " + str(pts.size()))
	#print("With turn2: " + str(pts))
	
	# TODO: potential optimization - add only key points to AStar
	# begin, turn1_end, turn2_end, beginning of turn2
	# add pts to nav (road-level AStar)
	for i in range(pts.size()):
		nav.add_point(i, pts[i])

	#print("IDs:" + var2str(nav.get_point_ids()))

	# connect the points
	var turn1_end = begin_id + turn1.points_center.size()-1
	# because of i+1
	for i in range(begin_id, turn1_end):
		if nav.has_point(i) and nav.has_point(i+1):
			nav.connect_points(i, i+1)

	var turn2_end = begin_id + turn1.points_center.size()+turn2.points_center.size()-1 #33+32 = 65
	for i in range(begin_id + turn1.points_center.size(), turn2_end):
		if nav.has_point(i) and nav.has_point(i+1):
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
	# the first two are used for calculating begin in setup_map_nav() and for AStar
	return [endpoint_id, last_id, ret]

# -------------------------------------------------------------
func setup_marker(marker, marker_data, begin_id, end_id):
	var tg = marker.target
	#print("tg:", tg)
	var int_path = ast.get_id_path(marker_data[begin_id], marker_data[end_id])
	print("Intersections path: " + var2str(int_path))
	var raceline = PackedVector3Array()
	for i in range(0, int_path.size()-1):
		var lookup_path = path_look[[int_path[i], int_path[i+1]]]
		var tmp_path = nav.get_point_path(lookup_path[0], lookup_path[1])
		raceline = raceline + tmp_path
	# assign the raceline
	marker.raceline = raceline

func setup_markers(marker_data):
	# if we have something to set up
	if marker_data != null:
		var marker = get_parent().get_marker("tt_marker")
		setup_marker(marker, marker_data, 0, 1)
		marker = get_parent().get_marker("race_marker")
		setup_marker(marker, marker_data, 2, 3)
		
		# circuit marker
		marker = get_parent().get_marker("circuit_marker")
		print("Circuit intersections path: " + var2str(marker.cycle))
		var nav_path = PackedVector3Array()
		for i in range(0, marker.cycle.size()-1):
			#print("Entry: #", i, ": ", marker.cycle[i])
			var lookup_path = path_look[[marker.cycle[i], marker.cycle[i+1]]]
			var tmp_path = nav.get_point_path(lookup_path[0], lookup_path[1])
			nav_path = nav_path + tmp_path
		
		# close the loop
		var lookup_path = path_look[[marker.cycle[marker.cycle.size()-1], marker.cycle[0]]]
		var tmp_path = nav.get_point_path(lookup_path[0], lookup_path[1])
		nav_path = nav_path + tmp_path
		
		# assign the raceline
		marker.raceline = nav_path

# ------------------------------------
func get_closest_road(gl):
	var roads = get_tree().get_nodes_in_group("roads")
	var dists = []
	var targs = []
	
	for r in roads:
		#var dist = r.get_global_position().distance_to(gl)
		var dist = r.get_global_positions()[1].distance_to(gl)
		dists.append(dist)
		targs.append([dist, r])

	dists.sort()
	#print("Dists sorted: " + str(dists))
	
	for t in targs:
		if t[0] == dists[0]:
			print("Closest road is : ", t[1].get_name())
			
			return t[1]

# ---------------------------------------

# this is governed by map not AI (so that lanes are picked consistently depending on direction of travel)
# note to self: it doesn't care about the straight, just the turns
# TODO: precalculate it, at least partially?
func get_lane(road, flip, left_side):
	# paranoia
	if not road.has_node("Road_instance0"):
		return
	if not road.has_node("Road_instance1"):
		return

	# this led to a weird bug elsewhere?
	# fix: int_path has to be flipped, too
	#if flip:
	#	int_path[0] = int_path[1]
	#	int_path[1] = int_path[0]
	
	# extract intersection numbers
	var ret = []
	var strs = String(road.get_name()).split("-")
	# convert to int
	ret.append(strs[0].lstrip("Road ").to_int())
	ret.append(strs[1].to_int())

	# shortcut (we know map has 3 nodes before intersections)
	var src = get_parent().get_child(ret[0]+3)
	var dst = get_parent().get_child(ret[1]+3)
	# which direction are we going?
	var rel_pos = (dst.get_global_transform() * src.get_global_transform().origin)
	# same as in connect_intersections.gd
	# by convention, y comes first
	var angle = atan2(rel_pos.z, rel_pos.x)
	
	var quadrant = get_quadrant(rel_pos)
		
	print(String(road.get_name()), " rel pos road start-end: ", rel_pos, " angle: ", angle, " ", rad2deg(angle), " deg, quadrant ", quadrant)
	
	# this part actually gets the points
	#TODO: unique nodes
	var turn1 = road.get_node(^"Road_instance0").get_child(0).get_child(0)
	var turn2 = road.get_node(^"Road_instance1").get_child(0).get_child(0)

	var offsets = reference_pos(road, src, dst, turn1, turn2, false)
	var cross = false
	if (offsets[0] < 0) == (offsets[1] < 0):
		print(String(road.get_name()), " predict lanes will cross!")
		cross = true
		
	# default
	var lane_lists = [turn1.points_inner_nav, turn2.points_outer_nav]
	
	# fix crossing over
	# SE - inner offset < 0 is correct (left lane)
	if quadrant == "SE" and cross:
		lane_lists = [turn1.points_inner_nav, turn2.points_inner_nav]
	# NE - inner offset > 0 results in right lane
	if quadrant == "NE" and cross:
		lane_lists = [turn1.points_outer_nav, turn2.points_outer_nav]
	# NW - inner offset > 0 results in right lane
	if quadrant == "NW" and cross:
		lane_lists = [turn1.points_outer_nav, turn2.points_outer_nav]
	
	# fix - crossing over was already handled
	if not cross:
		# fix more badness - 7-1, 4-3 and 3-2 have issues
		# NE - inner offset > 0 results in right lane (7-1 and 4-3)
		if quadrant == "NE" and offsets[0] > 0:
			#print(road.get_name(), " needs a fix - NE")
			lane_lists = [turn1.points_outer_nav, turn2.points_inner_nav]
		# NW - inner_offset > 0 results in right lane
		if quadrant == "NW" and offsets[0] > 0:
			lane_lists = [turn1.points_outer_nav, turn2.points_inner_nav]
		
	
	var pts = []
	
	if flip:
		# generate the other lane
		var o_lane_lists = other_lane(lane_lists, turn1, turn2)
		pts = get_pts_from_lanes(o_lane_lists, true, turn1, turn2)
	else:
		pts = get_pts_from_lanes(lane_lists, false, turn1, turn2)

	# left and flip are used mostly for debugging
	return [pts, left_side, flip]


func get_pts_from_lanes(lanes, flip, turn1, turn2):
	var pts = []
	# keeping 'em global for consistency with the A* centerline/raceline
	# from local to global
	#print("Turn size: ", lane_lists[0].size())
	
	for i in range(0,lanes[0].size()):
		var c = lanes[0][i]
		var p = Vector3(c.x, turn1.road_height, c.y)
		pts.append(turn1.to_global(p))

	#print(pts)
	#print("Points: ", pts.size()) # 33
	
	# because turn 2 is inverted
	for i in range(lanes[1].size()-1, 0, -1):
		var c = lanes[1][i]
		var p = Vector3(c.x, turn1.road_height, c.y)
		pts.append(turn2.to_global(p))
	#print("Points with turn 2: ", pts.size()) # 65 = 33+32

	if flip:
		pts.reverse()
		
	var midpoint = get_lane_midpoint(pts, flip)
	pts.append(midpoint)
	
	return pts

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
		#print("Path3D considered: " + str(p))
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
				paths.remove_at(paths.find(p))
	print("Possible paths for id : " + var2str(id) + " " + var2str(paths))
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
	

func reference_pos(road, src, dst, turn1, turn2, flip):
	#print("Inner 0: ", turn1.points_inner_nav[0], "outer 0", turn2.points_outer_nav[0])
	
	# from intersection, looking at start point
	# this is less readable but more optimized compared to creating two nodes per call
	var src_tr = Transform3D(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1), src.get_global_transform().origin)
	var dst_tr = Transform3D(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1), dst.get_global_transform().origin)

	if not flip:
		src_tr = src_tr.looking_at(turn1.to_global(turn1.start_point), Vector3.UP)
		dst_tr = dst_tr.looking_at(turn2.to_global(turn2.start_point), Vector3.UP)
	else:
		src_tr = src_tr.looking_at(turn2.to_global(turn2.start_point), Vector3.UP)
		dst_tr = dst_tr.looking_at(turn1.to_global(turn1.start_point), Vector3.UP)
	
	# test
	var inn = Vector3(turn1.points_inner_nav[0].x, 0.01, turn1.points_inner_nav[0].y)
	var out = Vector3(turn2.points_outer_nav[0].x, 0.01, turn2.points_outer_nav[0].y)
	
	# positions relative to refpoint
	# x <0 right > 0 left
	var inner_offset = null
	var outer_offset = null
	if not flip:
		#inner_offset = test_src.to_local(turn1.to_global(inn))
		inner_offset = turn1.to_global(inn) * src_tr
		#print(road.get_name(), " inner offset ", inner_offset.x, " right: ", inner_offset.x < 0)
		#outer_offset = test_dst.to_local(turn2.to_global(out))
		outer_offset = turn2.to_global(out) * dst_tr
	else:
		#outer_offset = test_src.to_local(turn2.to_global(out))
		outer_offset = turn2.to_global(out) * src_tr
		#print(road.get_name(), " outer offset ", outer_offset.x, " right: ", outer_offset.x < 0)
		#inner_offset = test_dst.to_local(turn1.to_global(inn))
		inner_offset = turn1.to_global(inn) * dst_tr
	
	#debug_cube(to_local(turn1.to_global(Vector3(turn1.points_inner_nav[0].x, 0.5, turn1.points_inner_nav[0].y))), "left_flip") # blue
	#debug_cube(to_local(turn2.to_global(Vector3(turn2.points_outer_nav[0].x, 0.5, turn2.points_outer_nav[0].y))), "left") # black
	
	return [inner_offset.x, outer_offset.x]
	
func other_lane(lanes, turn1, turn2):
	#print("Getting the other lane for lane: ", lanes)
	var lane_lists = []
	
	if lanes == [turn1.points_inner_nav, turn2.points_inner_nav]:
		#print("Lane 1 is inners only")
		lane_lists = [turn1.points_outer_nav, turn2.points_outer_nav]
	if lanes == [turn1.points_outer_nav, turn2.points_outer_nav]:
		#print("Lane 1 is outers only")
		lane_lists = [turn1.points_inner_nav, turn2.points_inner_nav]
	if lanes == [turn1.points_inner_nav, turn2.points_outer_nav]:
		lane_lists = [turn1.points_outer_nav, turn2.points_inner_nav]
	if lanes == [turn1.points_outer_nav, turn2.points_inner_nav]:
		lane_lists = [turn1.points_inner_nav, turn2.points_outer_nav]
	return lane_lists

# -----------------------------------------
# lower level than lanes
func debug_lane_lists():
	var map = get_parent()
	for p in path_look:
		#print(str(p))
		
		# get road from ids
		var rd_name = "Road "+str(p[0])+"-"+str(p[1])
		# IMPORTANT!!!
		var flip = false
	
		if not map.has_node(rd_name):
			# skip (since flip just reverses the order, no need to debug it)
			continue

		#print("Road name: " + rd_name)
		var road = map.get_node(rd_name)
		
		#TODO: call get_lane() here
		
		# paranoia
		if not road.has_node("Road_instance0"):
			return
		if not road.has_node("Road_instance1"):
			return

		# shortcut (we know map has 3 nodes before intersections)
		var src = map.get_child(p[0]+3)
		var dst = map.get_child(p[1]+3)
		# which direction are we going?
		var rel_pos = (dst.get_global_transform() * src.get_global_transform().origin)
		# same as in connect_intersections.gd
		# by convention, y comes first
		var angle = atan2(rel_pos.z, rel_pos.x)
		var quadrant = get_quadrant(rel_pos)
		
		print(String(road.get_name()), " rel pos road start-end: ", rel_pos, " angle: ", angle, " ", rad2deg(angle), " deg, quadrant ", quadrant)
		
		
		# this part actually gets A* points
		var turn1 = road.get_node(^"Road_instance0").get_child(0).get_child(0)
		var turn2 = road.get_node(^"Road_instance1").get_child(0).get_child(0)
	
		var offsets = reference_pos(road, src, dst, turn1, turn2, flip)
		var cross = false
		if (offsets[0] < 0) == (offsets[1] < 0):
			print(String(road.get_name()), " predict lanes will cross!")
			cross = true
			
		# default
		var lane_lists = [turn1.points_inner_nav, turn2.points_outer_nav]
		
		# fix crossing over
		# SE - inner offset < 0 is correct (left lane)
		if quadrant == "SE" and cross:
			lane_lists = [turn1.points_inner_nav, turn2.points_inner_nav]
		# NE - inner offset > 0 results in right lane
		if quadrant == "NE" and cross:
			lane_lists = [turn1.points_outer_nav, turn2.points_outer_nav]
		# NW - inner offset > 0 results in right lane
		if quadrant == "NW" and cross:
			lane_lists = [turn1.points_outer_nav, turn2.points_outer_nav]
		
		# fix - crossing over was already handled
		if not cross:
			# fix more badness - 7-1, 4-3 and 3-2 have issues
			# NE - inner offset > 0 results in right lane (7-1 and 4-3)
			if quadrant == "NE" and offsets[0] > 0:
				#print(road.get_name(), " needs a fix - NE")
				lane_lists = [turn1.points_outer_nav, turn2.points_inner_nav]
			# NW - inner_offset > 0 results in right lane
			if quadrant == "NW" and offsets[0] > 0:
				lane_lists = [turn1.points_outer_nav, turn2.points_inner_nav]
			
		
		var pts = get_pts_from_lanes(lane_lists, flip, turn1, turn2)
		
		# detect bugs
		# those two should line up relative to the straight part of the road
		var midpoint_offset = road.get_node(^"Spatial0/Road_instance 0").to_local(pts[pts.size()-1]).x
		var turn_offset = road.get_node(^"Spatial0/Road_instance 0").to_local(pts[33]).x
		if abs(midpoint_offset-turn_offset) > 0.75:
			print("Bug! Lanes crossing over for road ", road.get_name())
			# debugging
			#debug_cube(to_local(turn1.to_global(turn1.start_point)))
			#debug_cube(to_local(turn2.to_global(turn2.start_point)))

		# black means it's the left lane when driving as the road was designed (with traffic)
		# A->B (eg. 7 to 0 for road 7-0)
		# red means it's the left lane when driving flipped

		
		# debug which way the road was designed
		# B-A - A->B
		var src_debug = src.get_global_transform().origin+(turn1.to_global(turn1.start_point)-src.get_global_transform().origin).normalized()
		var dst_debug = dst.get_global_transform().origin+(turn2.to_global(turn2.start_point)-dst.get_global_transform().origin).normalized()
		debug_cube(to_local(src_debug), "left") # black (with traffic for designed direction)
		debug_cube(to_local(dst_debug), "flip") # red (oncoming)
		
		# those points are global (see line 442)
		for pt in pts:
			debug_cube(to_local(pt), "left") # black, counterpart to white
			
		# generate the other lane
		var o_lane_lists = other_lane(lane_lists, turn1, turn2)
		var o_pts = get_pts_from_lanes(o_lane_lists, flip, turn1, turn2)
		
		# those points are global (see line 442)
		for pt in o_pts:
			debug_cube(to_local(pt), "flip") # red

			
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
	
	var p3 = p4.limit_length(3)
	debug_cube(to_local(closest.get_global_transform().origin+Vector3(p3.x, 0.01, p3.y)), "flip")
	return get_node("/root/Geom").make_arc_from_points(p1, p2, p3, closest.get_global_transform().origin)

# debugging
# loc is, well, LOCAL!!!
func debug_cube(loc, flag=""):
	var mesh = BoxMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance3D.new()
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
	node.set_position(loc)
	# offset flipped a bit
	if flag == "flip" or flag == "left_flip":
		node.translate(Vector3(0.0, 0.2, 0.0))
	
func clear_cubes():
	for c in get_children():
		if c.is_in_group("debug") and c.is_class("MeshInstance3D"):
			c.queue_free()

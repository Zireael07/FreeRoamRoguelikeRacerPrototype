tool
extends Spatial

var ast # for BFS
var nav # for actual navigation
var path_look = {} # calculated paths

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
	var p = samples[id]

	var sp_marker = sp_mark.instance()
	sp_marker.set_translation(Vector3(p[0]*mult, 0, p[1]*mult))
	add_child(sp_marker)

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
		
		# the same for race marker	
		marker = get_parent().get_marker("race_marker")
		#marker = get_node("race_marker")
	#print(marker.get_translation())
		tg = marker.target
	#print("tg : " + str(tg))

#	print("Marker intersection id" + str(marker_data[0]) + " tg id" + str(marker_data[1]))
		int_path = ast.get_id_path(marker_data[2], marker_data[3])
		print("Intersections path: " + str(int_path))

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
	#print("Index: " + str(i) + " " + get_child(i).get_name())
	#print(get_child(i).get_name())
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

func get_lane(road, flip, left_side):
	var pts = []
	# paranoia
	if not road.has_node("Road_instance0"):
		return
	if not road.has_node("Road_instance1"):
		return

	var turn1 = road.get_node("Road_instance0").get_child(0).get_child(0)
	var turn2 = road.get_node("Road_instance1").get_child(0).get_child(0)
	
	var lane_lists = []
	# side
	if left_side:
		if not flip:
			lane_lists = [turn1.points_inner_nav, turn2.points_outer_nav]
		else:
			lane_lists = [turn1.points_outer_nav, turn2.points_inner_nav]
	else:
		if not flip:
			lane_lists = [turn1.points_outer_nav, turn2.points_inner_nav]
		else:
			lane_lists = [turn1.points_inner_nav, turn2.points_outer_nav]

	# keeping 'em global for consistency with the A* centerline
	# from local to global
	for i in range(0,lane_lists[0].size()):
		var c = lane_lists[0][i]
		var p = Vector3(c.x, turn1.road_height, c.y)
		pts.append(turn1.to_global(p))

	#print(pts)
	# because turn 2 is inverted
	for i in range(lane_lists[1].size()-1, 0, -1):
		var c = lane_lists[1][i]
		var p = Vector3(c.x, turn1.road_height, c.y)
		pts.append(turn2.to_global(p))

	if flip:
		pts.invert()

	return pts

# called from the outside, eg. by AI when pathing
func get_path_look(id, exclude=-1):
	print("Get path for id: " + str(id) + ", exclude: " + str(exclude))
	#print("Path_look: " + str(self.path_look))
	var int_path = null
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
		return paths[0]

	# remove excluded paths
	if exclude != -1:
		for p in paths:
			if p[1] == exclude:
				paths.remove(paths.find(p))
	
	print("Possible paths for id : " + str(id) + " " + str(paths))
	
	# if only one path after we removed exclusions, just pick it
	if paths.size() == 1:
		return paths[0]
		
	# randomize selection
	randomize()
	id = randi() % paths.size()
	int_path = paths[id]
				
	return int_path


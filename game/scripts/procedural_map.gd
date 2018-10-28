tool
extends "connect_intersections.gd"

# class member variables go here, for example:
var intersects
var mult
	
var edges = []
var samples = []
var as

var nav
#var tris = []

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	mult = get_node("triangulate/poisson").mult
	
	intersects = preload("res://roads/intersection.tscn")
	
	samples = get_node("triangulate/poisson").samples
	
	for i in range(0, get_node("triangulate/poisson").samples.size()-1):
		var p = get_node("triangulate/poisson").samples[i]
		var intersection = intersects.instance()
		intersection.set_translation(Vector3(p[0]*mult, 0, p[1]*mult))
		intersection.set_name("intersection" + str(i))
		add_child(intersection)
	
	# get the triangulation
	var tris = get_node("triangulate").tris
	
	for t in tris:
		#var poly = []
		#print("Edges: " + str(t.get_edges()))
		for e in t.get_edges():
			edges.append(e)
	
	# create the map
	for i in range(0, edges.size()):
		var ed = edges[i]
		#print("Connecting intersections for edge: " + str(i) + " 0: " + str(ed[0]) + " 1: " + str(ed[1]))
		var p1 = samples[ed[0]]
		var p2 = samples[ed[1]]
		# +1 because of the poisson node that comes first
		connect_intersections(ed[0]+2, ed[1]+2)
	
	
	setup_neighbors()
	
	spawn_markers()
	
	# test
	var roads_start_id = 2+5 # 2 helper nodes + 5 intersections
	
	nav = AStar.new()
	var pts = []
	for i in range(roads_start_id, roads_start_id+4):
		print(get_child(i).get_name())
		var turn1 = get_child(i).get_node("Road_instance0").get_child(0).get_child(0)
		var turn2 = get_child(i).get_node("Road_instance1").get_child(0).get_child(0)
		
		#print("Straight positions: " + str(get_child(i).get_node("Spatial0").get_child(0).positions))
		#print("Turn 1 positions: " + str(turn1.positions))
		#print("Turn 2 positions: " + str(turn2.positions))
		
		# from local to global
		for p in turn1.positions:
			pts.append(turn1.get_global_transform().xform(p))
		for p in turn2.positions:
			pts.append(turn2.get_global_transform().xform(p))

		# add pts to nav (road-level AStar)
		for i in range(pts.size()):
			nav.add_point(i, pts[i])
			
		# connect the points
		# because of i+1
		for i in range(turn1.positions.size()-1):
			nav.connect_points(i, i+1)
		
		for i in range(turn1.positions.size(), turn1.positions.size()+turn2.positions.size()-1):
			nav.connect_points(i, i+1)
			
		# connect the endpoints
		nav.connect_points(turn1.positions.size()-1, turn1.positions.size())
		
		# test
		var endpoint_id = turn1.positions.size()+turn2.positions.size()-2
		print("Endpoint id " + str(endpoint_id))
		print("Test: " + str(nav.get_point_path(0, endpoint_id)))

		#print(pts)
				

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

#-------------------------
# Distance map

func setup_neighbors():
	# we'll use AStar to have an easy map of neighbors
	as = AStar.new()
	for i in range(0,samples.size()-1):
		as.add_point(i, Vector3(samples[i][0]*mult, 0, samples[i][1]*mult))

	for i in range(0, edges.size()):
		var ed = edges[i]
		as.connect_points(ed[0], ed[1])

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
		print("Visiting... " + str(node))
		
		var neighbours = as.get_point_connections(node)
		# add neighbours of node to queue
		for neighbour in neighbours:
			# if not visited
			#if not explored.has(neighbour):
			if not distance.has(neighbour):
				queue.append(neighbour)
				distance[neighbour] = 1 + distance[node]
		
	
	return distance
	

#-------------------------

func spawn_markers():
	var spots = []
	
	var mark = preload("res://objects/marker.tscn")
	var sp_mark = preload("res://objects/speed_marker.tscn")
	
	# random choice of an intersection to spawn at
	# trick to copy the array
	spots = [] + samples
	spots.pop_back() # we don't want the last entry
	var num_inters = spots.size()
	var id = randi() % num_inters
	var p = spots[id]
	
	var sp_marker = sp_mark.instance()
	sp_marker.set_translation(Vector3(p[0]*mult, 0, p[1]*mult))
	add_child(sp_marker)
	
	# remove from list of possible spots
	spots.remove(id)

	# random choice of an intersection to spawn at
	id = randi() % spots.size()
	p = spots[id]
	var marker = mark.instance()
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
		if v > 1:
			print("Possible target id: " + str(n))
			possible_targets.append(n)
	
	var t_id = null
	if possible_targets.size() > 1:
		# pick randomly
		t_id = possible_targets[randi() % possible_targets.size()]
	else:
		t_id = possible_targets[0]
		
	print("Target id: " + str(t_id))
	
	marker.target = Vector3(samples[t_id][0]*mult, 0, samples[t_id][1]*mult)
	print("Marker target is " + str(marker.target))
	
	add_child(marker)
	

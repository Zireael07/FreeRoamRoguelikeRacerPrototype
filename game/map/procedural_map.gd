tool
extends "connect_intersections.gd"

# class member variables go here, for example:
var intersects
var mult

var edges = []
var samples = []
#var tris = []

var garage
var recharge

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here

	mult = get_node("triangulate/poisson").mult

	intersects = preload("res://roads/intersection4way.tscn")
	garage = preload("res://objects/garage_road.tscn")
	recharge = preload("res://objects/recharge_station.tscn")

	samples = get_node("triangulate/poisson").samples
	print("Number of intersections: " + str(samples.size()-1))
	for i in range(0, get_node("triangulate/poisson").samples.size()-1):
		var p = get_node("triangulate/poisson").samples[i]
		var intersection = intersects.instance()
		intersection.set_translation(Vector3(p[0]*mult, 0, p[1]*mult))
		#print("Placing intersection at " + str(p[0]*mult) + ", " + str(p[1]*mult))
		intersection.set_name("intersection" + str(i))
		add_child(intersection)

	# get the triangulation
	var tris = get_node("triangulate").tris

	for t in tris:
		#var poly = []
		#print("Edges: " + str(t.get_edges()))
		for e in t.get_edges():
			#print(str(e))
			if edges.has(Vector2(e[0], e[1])):
				pass
				#print("Already has edge: " + str(e[0]) + " " + str(e[1]))
			elif edges.has(Vector2(e[1], e[0])):
				pass
				#print("Already has edge: " + str(e[1]) + " " + str(e[0]))
			else:
				edges.append(e)

	# create the map
	# for storing roads that actually got created
	var real_edges = []
	var sorted = sort_intersections_distance()

#	var initial_int = sorted[0][1]
#	print("Initial int: " + str(initial_int))

	# automate it!
	for i in range(sorted.size()-1):
		auto_connect(sorted[i][1], real_edges)
	
#	auto_connect(sorted[0][1], real_edges)
#	auto_connect(sorted[1][1], real_edges)
#	auto_connect(sorted[2][1], real_edges)
#	auto_connect(sorted[3][1], real_edges)
#	auto_connect(sorted[4][1], real_edges)
#	auto_connect(sorted[5][1], real_edges)
#	auto_connect(sorted[6][1], real_edges)
#	auto_connect(sorted[7][1], real_edges)

	# road around
	var out_edges = get_node("triangulate/poisson").out_edges
	print("Outer edges: " + str(out_edges))

	# remove any edges that we already connected
	var to_remove = []
	for e in real_edges:
		#print("Check real edge: " + str(e))
		#out_edges.remove(out_edges.find(e))
		for i in range(0, out_edges.size()):
			var e_o = out_edges[i]
			#print("Outer edge: " + str(e_o))
			if e[0] == e_o[0] and e[1] == e_o[1]:
				to_remove.append(e_o)
			# check the other way round, too
			if e[1] == e_o[0] and e[0] == e_o[1]:
				to_remove.append(e_o)
				
	for e in to_remove:
		#print("To remove: " + str(e))
		# works because e is taken directly from out_edges (see line 87)
		out_edges.remove(out_edges.find(e))
		
	print("Outer edges post filter: " + str(out_edges))

#	for e in out_edges:
#		# +3 because of helper nodes which come first
#		var ret = connect_intersections(e[0]+3, e[1]+3, false)
#		if ret != false:
#			# update naming
#			fix_road_naming()

	# map navigation, markers...
	get_node("nav").setup(mult, samples, real_edges)

	# place cars on intersection
	place_player(1)
	place_AI(1)

	# place garage road
	var garage_opts = []
	for i in range(3, samples.size()-1):
		var inters = get_child(i)
		#Logger.mapgen_print(inters.get_name() + " exits: " + str(inters.open_exits))
		if inters.open_exits.size() > 1:
			# is it in the edges that actually were connected?
			for e in real_edges:
				if e.x == i or e.y == i:
					Logger.mapgen_print(inters.get_name() + " is an option for garage road")
					garage_opts.append(inters)
					break #the first find should be enough
			
			if garage_opts.find(inters) == -1:
				pass
				#Logger.mapgen_print(inters.get_name() + " is not in the actual connected map")
				
	var sel = null
	if not garage_opts:
		print("No garage options found")
		return

#	if garage_opts.size() > 1:
#		sel = garage_opts[randi() % garage_opts.size()]
#	else:
#		sel = garage_opts[0]

	var rots = { Vector3(10,0,0): Vector3(0,-90,0), Vector3(0,0,10): Vector3(0, 180, 0), Vector3(-10,0,0) : Vector3(0, 90, 0) }

	# force for testing
	var wanted = get_child(3) # intersection 0
	sel = wanted

	if sel.open_exits.size() > 0:
		print(sel.get_name() + str(sel.open_exits[0]))
		var garage_rd = garage.instance()
		# test placement
		garage_rd.set_translation(sel.get_translation() + sel.open_exits[0])
		#print(str(garage_rd.get_translation()))
		#print(str(sel.open_exits[1]))
		
		# assign correct rotation
		if rots.has(sel.open_exits[0]): 
			garage_rd.set_rotation_degrees(rots[sel.open_exits[0]])
		else:
			# prevent weirdness
			print("Couldn't find correct rotation for " + str(sel.open_exits[0]))
			return
		
		add_child(garage_rd)
	
	# place recharging station
	wanted = get_child(6) # intersection 3
	sel = wanted
	if sel.open_exits.size() > 2:
		print(sel.get_name() + str(sel.open_exits[1]))
		var station = recharge.instance()
		# place including offset that accounts for the size
		station.set_translation(sel.get_translation() + sel.open_exits[1] + Vector3(4,0,4))
	
		# assign correct rotation
		if rots.has(sel.open_exits[1]): 
			station.set_rotation_degrees(rots[sel.open_exits[1]])
	
		add_child(station)

# -----------------
# returns a list of [dist, index] lists, operates on child ids
func sort_intersections_distance(tg = Vector3(0,0,0), debug=true):
	var dists = []
	var tmp = []
	var closest = []
	# exclude helper nodes
	for i in range(3, 3+samples.size()-1):
		var e = get_child(i)
		var dist = e.translation.distance_to(tg)
		#print("Distance: exit: " + str(e.get_name()) + " dist: " + str(dist))
		tmp.append([dist, i])
		dists.append(dist)

	dists.sort()

	#print("tmp" + str(tmp))
	# while causes a lockup, whichever way we do it
	#while tmp.size() > 0:
	#	print("Tmp size > 0")
	var max_s = tmp.size()
	#while max_s > 0:
	for i in range(0, max_s):
		#print("Running add, attempt " + str(i))
		#print("tmp: " + str(tmp))
		for t in tmp:
			#print("Check t " + str(t))
			if t[0] == dists[0]:
				closest.append(t)
				tmp.remove(tmp.find(t))
				# key line
				dists.remove(0)
				#print("Adding " + str(t))
	# if it's not empty by now, we have an issue
	#print(tmp)

	if debug:
		print("Sorted inters: " + str(closest))

	return closest

func auto_connect(initial_int, real_edges, verbose=false):
	var next_ints = []
	var res = []
	var sorted_n = []
	# to remove properly
	var to_remove = []

	if verbose:
		# +3 because of helper nodes that come first
		Logger.mapgen_print("Auto connecting... " + get_child(initial_int+3).get_name() + " @ " + str(get_child(initial_int+3).get_global_transform().origin))

	for e in edges:
		if e.x == initial_int:
			#Logger.mapgen_print("Edge with initial int" + str(e) + " other end " + str(e.y))
			var data = [e.y, get_child(e.y).get_global_transform().origin]
			next_ints.append(data)
			#print(data[1].x)
			#TODO: use relative angles?? it has to be robust!
			sorted_n.append(atan2(data[1].z, data[1].x))
			#sorted_n.append(data[1].x)
			# remove from edge list so that we can use the list in other iterations
			to_remove.append(edges.find(e))
		if e.y == initial_int:
			#Logger.mapgen_print("Edge with initial int" + str(e) + " other end " + str(e.x))
			var data = [e.x, get_child(e.x).get_global_transform().origin]
			next_ints.append(data)
			#print(data[1].x)
			#sorted_n.append(data[1].x)
			sorted_n.append(atan2(data[1].z, data[1].x))
			# remove from edge list so that we can use the list in other iterations
			to_remove.append(edges.find(e))

	# remove ids to remove
	#print("Before: " + str(to_remove))
	to_remove.sort()
	#print("Sorted: " + str(to_remove))
	# By removing highest index first, we avoid errors
	to_remove.invert()
	#print("Inverted: " + str(to_remove))
	for i in to_remove:
		edges.remove(i)

	#print(sorted_n)

	# this sorts by natural order (lower value first)
	sorted_n.sort()
	# but we want higher?
	#sorted_n.invert()

	if verbose:
		Logger.mapgen_print("Sorted: " + str(sorted_n))

	for i in range(0, next_ints.size()):
		#print("Attempt " + str(i))
		for d in next_ints:
			#print(str(d) + " " + str(sorted_n[0]))
			# the first part of this needs to match what was used for sorting
			if atan2(d[1].z, d[1].x) == sorted_n[0]:
				next_ints.remove(next_ints.find(d))
				res.append(d)
				sorted_n.remove(0)

	#print("Res " + str(res) + " lower y: " + str(res[0]))
	#print("next ints: " + str(next_ints))
	var last_int = 1+get_node("triangulate/poisson").samples.size()-1
	for i in range(0, res.size()):
		var p = res[i]
		#if verbose:
		#	Logger.mapgen_print("Intersection " + str(p))
		#Logger.mapgen_print("Target id " + str(p[0]+2) + "last intersection " + str(1+get_node("triangulate/poisson").samples.size()-1))
		# prevent trying to connect to unsuitable things
		if p[0]+3 > last_int:
			return
		# +3 because of helper nodes that come first
		var ret = connect_intersections(initial_int+3, p[0]+3, verbose)
		if ret != false:
			if verbose:
				Logger.mapgen_print("We did create a connection... " + str(initial_int) + " to " + str(p[0]))
			real_edges.append(Vector2(initial_int, p[0]))
			
			# update naming
			fix_road_naming()


func fix_road_naming():
	# update naming
	var added = get_child(get_child_count()-1)
	#print("Last child: " + added.get_name())
	
	# extract numbers (ids)
	var nrs = added.get_name().split("-")
	#print("Nrs: " + str(nrs))
	#nrs[0] = nrs[0].lstrip("Road ")
	#print("Nr" + str(nrs[0]))
	
	# in case of any @ in the latter part, strip them (and what follows)
	var nm = nrs[1].split("@")
	nrs[1] = nm[0]  

	var real = []
	# -3 because of the helper nodes ahead of intersections
	for i in nrs:
		real.append(int(i)-3)

	#Logger.mapgen_print(added.get_name() + " real numbers: " + str(real))
	added.set_name("Road " + str(real[0]) + "-" + str(real[1]))


func place_player_random():
	var player = get_tree().get_nodes_in_group("player")[0]

	var id = randi() % samples.size()-1
	var p = samples[id]

	var pos = Vector3(p[0]*mult, 0, p[1]*mult)

	# because player is child of root which is at 0,0,0
	player.set_translation(to_global(pos))

func place_player(id):
	var player = get_tree().get_nodes_in_group("player")[0]
	var p = samples[id]
	var pos = Vector3(p[0]*mult, 0, p[1]*mult)

	# because player is child of root which is at 0,0,0
	player.set_translation(to_global(pos))

func place_AI(id):
	var car = get_tree().get_nodes_in_group("AI")[0].get_parent()
	var p = samples[id]
	var pos = Vector3(p[0]*mult, 0, p[1]*mult)

	# because player is child of root which is at 0,0,0
	car.set_translation(to_global(pos))


func get_marker(_name):
	for c in get_children():
		if c.get_name().find(_name) != -1:
			return c

# markers are spawned in map_nav.gd because they use BFS/distance map


@tool
extends "connect_intersections.gd"

# prime candidate for rewriting in something speedier, along with triangulation itself (2dtests/Delaunay2D.gd)

# class member variables go here, for example:
var intersects
var mult

var edges = []
var samples = []

var real_edges = []
#var tris = []

var garage
var recharge
var dealership

var AI = preload("res://car/kinematics/kinematic_car_AI_traffic.tscn")

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	# need to do it explicitly in Godot 4 for some reason
	print("Map ready starts")
	super._ready()
	get_tree().paused = true

	mult = get_node(^"triangulate/poisson").mult

	intersects = preload("res://roads/intersection4way.tscn")
	garage = preload("res://objects/garage_road.tscn")
	recharge = preload("res://objects/recharge_station.tscn")
	dealership = preload("res://objects/dealer_city.tscn")

	samples = get_node(^"triangulate/poisson").samples
	
	if has_node("/root/Control/MapgenVis"):
		get_node("/root/Control/MapgenVis").prepare_labels(samples.size()-1)
	
	await mapgen()
	get_tree().paused = false
	EventBus.emit_signal("mapgen_done")
	print("Map ready done")
			
	# test
	#Logger.save_to_file()

func mapgen():
	await get_tree().process_frame # to avoid things getting out of order
	print("Number of intersections: " + str(samples.size()-1))
	for i in range(0, get_node(^"triangulate/poisson").samples.size()-1):
		var p = get_node(^"triangulate/poisson").samples[i]
		var intersection = intersects.instantiate()
		intersection.set_position(Vector3(p[0]*mult, 0, p[1]*mult))
		#print("Placing intersection at " + str(p[0]*mult) + ", " + str(p[1]*mult))
		intersection.set_name("intersection" + str(i))
		add_child(intersection)
		# visualization
		if has_node("/root/Control/MapgenVis"):
			await get_tree().process_frame
			get_node("/root/Control/MapgenVis").get_child(i).show()
			get_node("/root/Control/MapgenVis").get_child(i).set_text(var2str(i))
			get_node("/root/Control/MapgenVis").get_child(i).position = pos3d_to_vis_point(Vector3(p[0]*mult, 0, p[1]*mult))+Vector2(-15,-15)
			# draw a rect
			get_node("/root/Control/MapgenVis").rects.append(pos3d_to_vis_point(Vector3(p[0]*mult, 0, p[1]*mult)))
			get_node("/root/Control/MapgenVis").redraw()

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

	await get_tree().process_frame
	# create the map
	if has_node("/root/Control/Label"):
		get_node("/root/Control/Label").set_text("Created the map")
	# for storing roads that actually got created
	real_edges = []
	var sorted = sort_intersections_distance()

#	var initial_int = sorted[0][1]
#	print("Initial int: " + str(initial_int))

	# automate it!
	print("Auto connecting intersections...")
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

	#print("Real edges: ", real_edges)

	await get_tree().process_frame #hackfix
	await get_tree().process_frame
	print("Outer loop...")
	if has_node("/root/Control/Label"):
		get_node("/root/Control/Label").set_text("Making outer loop...")
	# road around
	var out_edges = get_node(^"triangulate/poisson").out_edges
	print("Outer edges: " + str(out_edges))
	var outer_loop = out_edges.duplicate()
	
	# paranoia
	if out_edges[0][0] != out_edges[out_edges.size()-1][1]:
		print("Start and end edge are different!")
	else:

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
			out_edges.remove_at(out_edges.find(e))
			
		print("Outer edges post filter: " + str(out_edges))

		for e in out_edges:
			#print("Out edge ", var2str(e[0]), ", ", var2str(e[1]))
			# feedback
			if has_node("/root/Control/Label"):
				await get_tree().process_frame
				do_connect(e[0], e[1], false)
				get_node("/root/Control/Label").set_text(String("Connecting intersections " + var2str(e[0]) + " " + var2str(e[1])))
			else:
				do_connect(e[0], e[1], false)

	await get_tree().process_frame
	# map setup is done, let's continue....
	if has_node("/root/Control/Label"):
		get_node("/root/Control/Label").set_text("Map navigation set up")
	# map navigation, markers...
	get_node(^"nav").setup(mult, samples, real_edges)

	# debug
#	get_node(^"nav").debug_lane_lists()

	# test: replace longest road with a bridge
#	# done after nav setup to avoid having to mess with navigation
	var elevated_data = elevate_outer_loop(outer_loop)

	# basic map is done, now sprinkle stuff around
	await get_tree().process_frame
	if has_node("/root/Control/Label"):
		get_node("/root/Control/Label").set_text("Spawning things...")
	# place cars on parking lots
	var lots = get_spawn_lots()
	
	#for i in range(2, samples.size()-1):
	for i in range(lots.size()):
		place_AI(i, lots)

	place_pois(elevated_data)

# ----------------------------------------
# sort
func sort_exits(a,b):
	if a.open_exits.size() > b.open_exits.size():
		return true
	return false

func place_pois(elevated_data):
	print("Elevated inters: ", elevated_data[0])
	# place garage road
	var poi_opts = []
	# exclude helper nodes
	for i in range(3, 3+samples.size()-1):
		#print("Checking intersection #", i, " ", get_child(i).get_name())
		if not i in elevated_data[0]:
			var inters = get_child(i)
			#Logger.mapgen_print(inters.get_name() + " exits: " + str(inters.open_exits))
			# at least one open exit
			if inters.open_exits.size() > 0:
				print("Intersection ", get_child(i).get_name(), " has open exits")
				# is it in the edges that actually were connected?
				for e in real_edges:
					# i - child node ids (real id +3)
					if e.x == i-3 or e.y == i-3:
						# prevent multiplicates
						if not inters in poi_opts:
							Logger.mapgen_print(String(inters.get_name()) + " is an option for POI")
							poi_opts.append(inters)
				
				if poi_opts.find(inters) == -1:
					pass
					#Logger.mapgen_print(inters.get_name() + " is not in the actual connected map")
	
	poi_opts.sort_custom(sort_exits)
					
	var sel = null
	if poi_opts.is_empty():
		print("No garage options found")
		return

	var rots = { Vector3(10,0,0): Vector3(0,-90,0), Vector3(0,0,10): Vector3(0, 180, 0), Vector3(-10,0,0) : Vector3(0, 90, 0) }

	#TODO: procedural choice for garage road (pointing away from center to make sure we have space for the road)
	
	# force for testing
	#var wanted = get_child(3) # intersection 0
	var wanted = poi_opts[0]
	sel = wanted

	if sel.open_exits.size() > 0:
		print(String(sel.get_name()) + str(sel.open_exits[0]))
		var garage_rd = garage.instantiate()
		# test placement
		garage_rd.set_position(sel.get_position() + sel.open_exits[0])
		#print(str(garage_rd.get_translation()))
		#print(str(sel.open_exits[1]))
		
		# assign correct rotation
		if rots.has(sel.open_exits[0]):
			var rot = rots[sel.open_exits[0]]
			garage_rd.set_rotation(Vector3(rot.x, deg2rad(rot.y), rot.z))
		else:
			# prevent weirdness
			print("Couldn't find correct rotation for " + str(sel.open_exits[0]))
			return
		
		add_child(garage_rd)
	
	# TODO: procedural POI placement system
	# place recharging station
	#wanted = get_child(6) # intersection 3
	wanted = poi_opts[1]
	sel = wanted
	if sel.open_exits.size() > 2:
		print(sel.get_name() + str(sel.open_exits[1]))
		var station = recharge.instantiate()
		# place including offset that accounts for the size
		station.set_position(sel.get_position() + sel.open_exits[1] + Vector3(4,0,4))
	
		# assign correct rotation
		if rots.has(sel.open_exits[1]):
			var rot = rots[sel.open_exits[1]]
			station.set_rotation(Vector3(rot.x, deg2rad(rot.y), rot.z))
	
		station.set_name("station")
		add_child(station)

	# place vehicle dealership
	sel = poi_opts[3]
	#sel = get_child(8) # intersection 5
	if sel.open_exits.size() > 0:
		print(String(sel.get_name()) + str(sel.open_exits[0]))
		var dealer = dealership.instantiate()
		# place
		dealer.set_position(sel.get_position() + sel.open_exits[0])
		
		# assign correct rotation
		if rots.has(sel.open_exits[0]):
			var rot = rots[sel.open_exits[0]]
			dealer.set_rotation(Vector3(rot.x, deg2rad(rot.y), rot.z))
		
		dealer.set_name("dealership")
		add_child(dealer)


# --------------------------------------
# returns a list of [dist, index] lists, operates on child ids
func sort_intersections_distance(tg = Vector3(0,0,0), debug=true):
	var dists = []
	var tmp = []
	var closest = []
	# exclude helper nodes
	for i in range(3, 3+samples.size()-1):
		var e = get_child(i)
		var dist = e.position.distance_to(tg)
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
				tmp.remove_at(tmp.find(t))
				# key line
				dists.remove_at(0)
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
		if initial_int+3 < get_child_count():
			# +3 because of helper nodes that come first
			Logger.mapgen_print("Auto connecting... " + String(get_child(initial_int+3).get_name()) + " @ " + str(get_child(initial_int+3).get_global_transform().origin))

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
	to_remove.reverse()
	#print("Inverted: " + str(to_remove))
	for i in to_remove:
		edges.remove_at(i)

	#print(sorted_n)

	# this sorts by natural order (lower value first)
	sorted_n.sort()
	# but we want higher?
	#sorted_n.reverse()

	if verbose:
		Logger.mapgen_print("Sorted: " + str(sorted_n))

	for i in range(0, next_ints.size()):
		#print("Attempt " + str(i))
		for d in next_ints:
			#print(str(d) + " " + str(sorted_n[0]))
			# the first part of this needs to match what was used for sorting
			if atan2(d[1].z, d[1].x) == sorted_n[0]:
				next_ints.remove_at(next_ints.find(d))
				res.append(d)
				sorted_n.remove_at(0)

	#print("Res " + str(res) + " lower y: " + str(res[0]))
	#print("next ints: " + str(next_ints))
	var last_int = 1+get_node(^"triangulate/poisson").samples.size()-1
	for i in range(0, res.size()):
		var p = res[i]
		#if verbose:
		#	Logger.mapgen_print("Intersection " + str(p))
		#Logger.mapgen_print("Target id " + str(p[0]+2) + "last intersection " + str(1+get_node(^"triangulate/poisson").samples.size()-1))
		# prevent trying to connect to unsuitable things
		if p[0]+3 > last_int:
			return
		# feedback
		if has_node("/root/Control/Label"):
			await get_tree().process_frame
			do_connect(initial_int, p[0], verbose)
			get_node("/root/Control/Label").set_text(String("Connecting intersections " + var2str(initial_int) + " " + var2str(p[0])))
		else:
			do_connect(initial_int, p[0], verbose)

# FIXME: bail out if the edge is already taken
func do_connect(s, end, verbose):
	# +3 because of helper nodes that come first
	var ret = connect_intersections(s+3, end+3, verbose)
	if ret != false:
		if verbose:
			Logger.mapgen_print("We did create a connection... " + str(s) + " to " + str(end))
		real_edges.append(Vector2(s, end))
		if has_node("/root/Control/MapgenVis"):
			#await a mouseclick maybe? 
			await get_tree().process_frame
			#await get_tree().create_timer(1.0).timeout
			get_node("/root/Control/MapgenVis").line = [s, end]
			get_node("/root/Control/MapgenVis").redraw()

# drawing
func pos3d_to_vis_point(pos):
	#the midpoint of map is equal to 0,0 in 3d
	#var middle = Vector2(0, 0) # 250,250
	var middle = Vector2(250,250)
	
	#print("Midpoint of map is " + String(middle))
	
	var x = round(middle.x - pos.x/2)
	var y = round(middle.y - pos.z/2)
	#print("Calculated position for pos " + String(pos) + "is x " + String(x) + " y " + String(y))
	
	#3d x is left/right (inc left) and z is forward/back (up/down)
	#2d x is left/right (increases right) and y is top/down (from top)
	return Vector2(x, y)

# ---------------------------------------
func find_road_for_edge(e):
	#print("Finding road for edge ", e)
	#print(var2str(int(e[0]))+"-"+var2str(int(e[1])))
	#print(var2str(int(e[1]))+"-"+var2str(int(e[0])))
	for c in get_children():
		#if "Road " in c.get_name():
		if (var2str(int(e[0]))+"-"+var2str(int(e[1]))) in c.get_name() or var2str(int(e[1]))+"-"+var2str(int(e[0])) in c.get_name():
				#print("Found road for edge: ", e, " ", c.get_name())
				return c

func replace_with_bridge(road):
	# originally Road 6-5
	var straight = road.get_node("Spatial0/Road_instance 0")
	var str_tr = road.get_node("Spatial0/Road_instance 0").get_position()
	var str_len = straight.relative_end
	var slope = set_straight_slope(str_tr, road.get_node(^"Spatial0/Road_instance 0").get_rotation(), road.get_node(^"Spatial0"), 1)
	# position the other end correctly
	var end_p_gl = straight.global_transform * (str_len)
	var end_p = road.get_node(^"Spatial0").to_local(end_p_gl)
	var slope2 = set_straight_slope(end_p, road.get_node(^"Spatial0/Road_instance 0").get_rotation()+Vector3(0,deg2rad(180),0), road.get_node(^"Spatial0"), 2)
	# regenerate the straight
	straight.translate_object_local(Vector3(0, 5, 40))
	straight.relative_end = Vector3(0,0,str_len.z-80) # because both slopes are 40 m long
	straight.get_node(^"plane").queue_free()
	straight.get_node(^"sidewalk").queue_free()
	# regenerate all the decor
	for c in straight.get_node(^"Node3D").get_children():
		c.queue_free()
	#straight.get_node(^"Node3D").queue_free()
	straight.generateRoad()

func elevate_outer_loop(loop):
	print("Outer loop: ", loop)
	var elevated_height = 5 #10
	var elevated_inters = []
	var elevated_roads = []
	
	for ei in range(loop.size()):
		var e = loop[ei]
		var road = find_road_for_edge(e)
		if road:
			road.translate_object_local(Vector3(0,elevated_height,0)) #elevate
			elevated_roads.append(road)
			var straight = road.get_node("Spatial0/Road_instance 0")
			# regenerate all the decor
			for c in straight.get_node(^"Node3D").get_children():
				c.queue_free()
			straight.generateRoad()
			
			# exclude helper nodes
			for i in range(3, 3+samples.size()-1):
				if i == e[1]+3 and not ei==loop.size()-1: # exclude final inters
					#print("Found intersection ", i)
					get_child(i).translate_object_local(Vector3(0,elevated_height,0)) # elevate intersections too
					elevated_inters.append(i) # appends child node ids (real id +3)

	print(elevated_inters)
	# unfortunately we need to loop again
	# exclude helper nodes
	for i in range(3, 3+samples.size()-1):
		#print("Checking i:", i, "inters: ", i-3)
		for r in elevated_roads:
			# extract intersection numbers
			var ret = []
			var strs = String(r.get_name()).split("-")
			# convert to int
			ret.append(strs[0].lstrip("Road ").to_int())
			ret.append(strs[1].to_int())
			# find non-elevated intersection
			if i == ret[0]+3 and not i in elevated_inters:
				var lower_inter_id = i-3
				print("Found non-elevated intersection, #",lower_inter_id)	
				#for r in elevated_roads:
				if var2str(lower_inter_id) in r.get_name():
					print("Road ", r.get_name(), " ends at non-elevated intersection!")
					# adjust the road
					var turn1 = r.get_node(^"Road_instance0").get_child(0).get_child(0)
					var turn2 = r.get_node(^"Road_instance1").get_child(0).get_child(0)
	
					turn1.road_slope = float(elevated_height)/(turn1.points_center.size()-1)
					print("Slope: ", turn1.road_slope, " calc end: ", turn1.road_height+(turn1.road_slope*(turn1.points_center.size()-1)))

					# hackfix
					turn1.calc()
					# regen the road
					turn1.create_road() # beginning and end don't change so that's all we need to call
					# lower it back down to ground
					turn1.translate_object_local(Vector3(0,-elevated_height,0))
					# fix collision for angled road
					turn1.get_node("StaticBody3D").translate_object_local(Vector3(0,0.5,0))
		
		# now check for non-elevated roads that link to elevated intersections
		if i in elevated_inters:
			for e in real_edges:
				if e[0]+3 == i or e[1]+3 == i:
					#print("Found real edge ", e, " ending at elevated inter: ", i-3)
					var r = find_road_for_edge(e)
					if r != null and not r in elevated_roads:
						#print("Found non-elevated road ", r.get_name(), " for edge ", e)
						print("Found non elevated road ", r.get_name(), " linking to intersection #", i-3)
			
						# adjust the road
						var turn1 = r.get_node(^"Road_instance0").get_child(0).get_child(0)
						var turn2 = r.get_node(^"Road_instance1").get_child(0).get_child(0)
		
						turn2.road_slope = -float(elevated_height)/(turn2.points_center.size()-1)
						print("Slope: ", turn2.road_slope, " calc end: ", turn2.road_height+(turn2.road_slope*(turn2.points_center.size()-1)))

						turn2.translate_object_local(Vector3(0,elevated_height,0))

						# hackfix
						turn2.calc()
						# regen the road
						turn2.create_road() # beginning and end don't change so that's all we need to call

						# fix collision for angled road
						turn2.get_node("StaticBody3D").translate_object_local(Vector3(0,0.5,0))
			
	print("Outer loop done!")
	return [elevated_inters]

# ---------------------------------------
func find_lot(road):
	for c in road.get_node(^"Spatial0/Road_instance 0/Node3D").get_children():
		if c.is_in_group("parking"):
			return c
			
func get_spawn_lots():
	var lots = []

	var roads_start_id = 3+samples.size()-1 # 3 helper nodes + intersections for samples
	#for e in real_edges:
	for i in range(roads_start_id, roads_start_id+ real_edges.size()):
		var road = get_child(i)
		if not road.get_node(^"Spatial0/Road_instance 0").tunnel:
			var lot = find_lot(road)
			if lot:
				lots.append([lot, lot.get_global_transform().origin])
	
	return lots

		

func place_player_random():
	var player = get_tree().get_nodes_in_group("player")[0]

	var id = randi() % samples.size()-1
	var p = samples[id]

	var pos = Vector3(p[0]*mult, 0, p[1]*mult)

	# because player is child of root which is at 0,0,0
	player.set_position(to_global(pos))

func place_player(id):
	var player = get_tree().get_nodes_in_group("player")[0]
	var p = samples[id]
	var pos = Vector3(p[0]*mult, 0, p[1]*mult)

	# because player is child of root which is at 0,0,0
	player.set_position(to_global(pos))

func place_AI(id, lots):
	var AI_g = get_parent().get_node(^"AI")
	#var car = get_tree().get_nodes_in_group("AI")[3] #.get_parent()
	
	var car = AI.instantiate()
	if AI_g == null:
		return
		
	AI_g.add_child(car)
	
	# this is global!
	var pos = lots[id][1]
	
	# this was local
	#var p = samples[id]
	#var pos = Vector3(p[0]*mult, 0, p[1]*mult)
	
	# to place on intersection exit (related to point_one/two/three in intersection.gd)
#	if exit == 1:
#		pos = pos + Vector3(0,0,5)
#	elif exit == 2:
#		pos = pos + Vector3(5,0,0)
#	elif exit == 3:
#		pos = pos + Vector3(0,0,-5)

	# because car is child of AI group node which is not at 0,0,0
	#car.set_position(AI_g.to_local(pos))
	
	# small offset
	var offset_pos = lots[id][0].to_global(Vector3(-4,0,0))
	car.set_position(AI_g.to_local(offset_pos))
	#car.translate_object_local(Vector3(0,0,-4))
	# rotate
	car.get_node("BODY").look_at(pos)

	print("placed AI on a lot #", var2str(id))

func get_marker(_name):
	for c in get_children():
		if String(c.get_name()).find(_name) != -1:
			return c

# markers are spawned in map_nav.gd because they use BFS/distance map


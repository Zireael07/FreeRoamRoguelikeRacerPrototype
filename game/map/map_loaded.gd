extends Node3D

# class member variables go here, for example:
var draw
var road_straight
var road

var intersects
var mult
var samples = []

var garage
var recharge
var dealership

# data
var data = []

# Called when the node enters the scene tree for the first time.
func _ready():
	draw = get_node(^"draw")
	road_straight = preload("res://roads/road_segment_straight.tscn")
	road = preload("res://roads/road_segment.tscn")
	
	mult = get_node(^"triangulate/poisson").mult

	intersects = preload("res://roads/intersection4way.tscn")
	garage = preload("res://objects/garage_road.tscn")
	recharge = preload("res://objects/recharge_station.tscn")
	dealership = preload("res://objects/dealer_city.tscn")

	# place intersections according to poisson/voronoi
	samples = get_node(^"triangulate/poisson").samples
	print("Number of intersections: " + str(samples.size()-1))
	for i in range(0, get_node(^"triangulate/poisson").samples.size()-1):
		var p = get_node(^"triangulate/poisson").samples[i]
		var intersection = intersects.instantiate()
		intersection.set_position(Vector3(p[0]*mult, 0, p[1]*mult))
		#print("Placing intersection at " + str(p[0]*mult) + ", " + str(p[1]*mult))
		intersection.set_name("intersection" + str(i))
		add_child(intersection)
		
		
	# load data
	data = load_data()
	#print(var2str(data))
	
	if data != null:
		for line in data:
			# line is [name, origin, basis, other data]
			print(str(line))
			
			var node = null
			if not has_node(line[0]):
				node = make_top_node(line[0])
			else:
				node = get_node(line[0])
				
			if line.size() == 6:
				print(line[0] + " has a curve" )
				var ind = 0
				if node.has_node("Road_instance0"):
					ind = 1
				# line is start_angle ([3]), end_angle ([4]), radius ([5])
				set_curved_road(line[5], line[3], line[4], ind, line[1], line[2], node)
				
			if line.size() == 5:
				print(line[0] + " has a straight")
				# line is dist ([3]), slope ([4])
				set_straight(line[3], line[1], line[2], node)
				
	print("Done setting up from data!")
					
# ------------------------------------------
func make_top_node(nm):
	# make top node (which holds road name)
	var top_node = Node3D.new()
	top_node.set_script(load("res://roads/road_top.gd"))
	
	top_node.set_name(nm)
	#top_node.set_name("Road " +str(one-3) + "-" + str(two-3))
	add_child(top_node)
	return top_node

# copied/based on connect_intersections.gd l. 332 onwards
func set_straight(relative_end, g_loc, _basis, node):
	var road_node = road_straight.instantiate()
	road_node.set_name("Road_instance 0")
	# set length
	#var dist = loc.distance_to(loc2)
	road_node.relative_end = relative_end
	var dist = relative_end.z
	
	# debug
	#debug_cube(Vector3(loc.x, 1, loc.z))
	#debug_cube(Vector3(loc2.x, 1, loc2.z))
	
	
	# decorate
	randomize()
	
	if dist > 51.0 and dist < 300:
		var r = randf()
		if r < 0.4:
			road_node.tunnel = true
	
	if dist < 51.0:
		var r = randf()
		if r < 0.2:
			road_node.bamboo = true
		elif r < 0.6:
			road_node.trees = true
	
	
	var spatial = Node3D.new()
	spatial.set_name("Spatial0")
	node.add_child(spatial)
	spatial.add_child(road_node)
	
	# place
	#spatial.set_position(loc)
	
	var tr = Transform3D(_basis, g_loc)
	spatial.set_global_transform(tr)
	#spatial.get_global_transform().origin = g_loc
	#spatial.get_global_transform().basis = _basis
	
	# looking down -Z
	#var tg = to_global(loc2)
	#print("Look at target: " + str(tg))
	
#	road_node.look_at(tg, Vector3(0,1,0))
#	# because we're pointing at +Z, sigh...
#	spatial.rotate_y(deg2rad(180))
	
	return road_node
	
func set_curved_road(radius, start_angle, end_angle, index, g_loc, _basis, node): #, verbose):
	if radius < 3: # less than lanes we want
		Logger.mapgen_print("Bad radius given!")
		return null

	var road_node_right = road.instantiate()
	road_node_right.set_name("Road_instance"+var2str(index))
	#set the radius we wanted
	road_node_right.get_child(0).get_child(0).radius = radius

#	if start_angle-90 > end_angle-90 and end_angle-90 < 0:
#		if verbose:
#			Logger.mapgen_print("Bad road settings: " + str(start_angle-90) + ", " + str(end_angle-90))
#		start_angle = start_angle+360
#
#	if verbose:
#		Logger.mapgen_print("Road settings: start: " + str(start_angle-90) + " end: " + str(end_angle-90))
#
#	# if start is negative and end is slightly positive, something probably went wrong
#	if start_angle - 90 < 0 and end_angle-90 > 0 and end_angle-90 < 90:
#		if verbose:
#			Logger.mapgen_print("Negative start but positive end: " + str(start_angle-90) + " end: " + str(end_angle-90))
#		# bring the end angle around
#		end_angle = end_angle + 360
	
	#set the angles we wanted
	# road angles are in respect to X axis, so let's subtract 90 to point down Y
	road_node_right.get_child(0).get_child(0).start_angle = start_angle #-90
	road_node_right.get_child(0).get_child(0).end_angle = end_angle #-90
	
	node.add_child(road_node_right)
	
	# place
	#road_node_right.get_child(0).get_global_transform().origin = g_loc
	#road_node_right.get_child(0).get_global_transform().basis = _basis
	var tr = Transform3D(_basis, g_loc)
	road_node_right.get_child(0).set_global_transform(tr)
	
	return road_node_right


# --------------------------------
func load_data():
	var file = File.new()
	var opened = file.open("res://mapdata.txt", file.READ)
	if opened == OK:
		while !file.eof_reached():
			#var csv = file.get_csv_line()
			var line = file.get_line()
			if line != null:
				# skip empty
				if line == "":
					continue
				var _line = str2var(line)

				# skip empty lines and "Spatial" entries
				if _line.size() > 1 and _line[0].find("Spatial") == -1:
					data.append(_line)
					#print(str(data))
	
		file.close()
		return data

# ----------------------------------------

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

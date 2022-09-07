@tool
extends "connect_intersections.gd"

var road_straight
var road

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	road_straight = preload("res://roads/road_segment_straight.tscn")
	road = preload("res://roads/road_segment.tscn")
	
func mesh_road_intersections(one, two, verbose):
	# make top node (which holds road name)
	var top_node = Node3D.new()
	top_node.set_script(load("res://roads/road_top.gd"))
	#print(str(one) + " to " + str(two))
	# this used to be child (node) id, but this way it's more intuitive
	# subtract 3 to get actual intersection number from child id
	top_node.set_name("Road " +str(one-3) + "-" + str(two-3))
	add_child(top_node)
	
	print(data)
	
	initial_road_attempt(one, two, data[0], data[1], top_node, verbose)
	last_turn_attempt(one, two, data[2], data[3], top_node, verbose)
	
	# can't rely on corner points because this sometimes leads to holes even though the turn angles are correct
	var turn1 = top_node.get_node("Road_instance0").get_child(0).get_child(0)
	var turn2 = top_node.get_node("Road_instance1").get_child(0).get_child(0)
	var loc1 = to_local(turn1.last * turn1.get_global_transform())
	var loc2 = to_local(turn2.last * turn2.get_global_transform())
	
	set_straight(loc1, loc2, top_node)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



	
func initial_road_attempt(one, two, turn_data, loc, node, verbose=false):
	if data == null:
		print("No first turn data, return")
		return
		
	var radius = turn_data[0]
	var start_angle = turn_data[1]
	var end_angle = turn_data[2]
	if verbose:
		print("First turn: R: " + str(radius) + " , start angle: " + str(start_angle) + " , end: " + str(end_angle))
	
	first_turn = set_curved_road(radius, start_angle, end_angle, 0, node, verbose)
	if first_turn != null:
		first_turn.set_position(loc)
	
		# place
		if get_child(two).get_position().y > get_child(one).get_position().y:
			pass
			#if verbose:
			#	Logger.mapgen_print("Road in normal direction, positive y")
		else:
			first_turn.rotate_y(deg2rad(180))
			#if verbose:
			#	Logger.mapgen_print("Rotated because we're going back")

func last_turn_attempt(one, two, turn_data, loc, node, verbose=false):
	if data == null:
		print("No last turn data, return")
		return
	
	var radius = turn_data[0]
	var start_angle = turn_data[1]
	var end_angle = turn_data[2]
	
	if verbose:
		print("Last turn: R: " + str(radius) + " , start angle: " + str(start_angle) + " , end: " + str(end_angle))
	
	last_turn = set_curved_road(radius, start_angle, end_angle, 1, node, verbose)
	if last_turn != null:
		last_turn.set_position(loc)
	
		# place
		if get_child(two).get_position().y > get_child(one).get_position().y:
			pass
			#if verbose:
			#	Logger.mapgen_print("Road in normal direction, positive y")
		else:
			last_turn.rotate_y(deg2rad(180))
			#if verbose:
			#	Logger.mapgen_print("Rotated because we're going back")
	
	
func set_straight(loc, loc2, node):
	var road_node = road_straight.instantiate()
	road_node.set_name("Road_instance 0")
	# set length
	var dist = loc.distance_to(loc2)
	road_node.relative_end = Vector3(0,0, dist)
	
	# debug
	
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
	spatial.set_position(loc)
	
	# looking down -Z
	var tg = to_global(loc2)
	#print("Look at target: " + str(tg))
	
	road_node.look_at(tg, Vector3(0,1,0))
	# because we're pointing at +Z, sigh...
	spatial.rotate_y(deg2rad(180))
	return road_node
	
func set_curved_road(radius, start_angle, end_angle, index, node, verbose):
	if radius < 3: # less than lanes we want
		Logger.mapgen_print("Bad radius given!")
		return null

	var road_node_right = road.instantiate()
	road_node_right.set_name("Road_instance"+var2str(index))
	#set the radius we wanted
	road_node_right.get_child(0).get_child(0).radius = radius

	if start_angle-90 > end_angle-90 and end_angle-90 < 0:
		if verbose:
			Logger.mapgen_print("Bad road settings: " + str(start_angle-90) + ", " + str(end_angle-90))
		start_angle = start_angle+360
	
	if verbose:
		Logger.mapgen_print("Road settings: start: " + str(start_angle-90) + " end: " + str(end_angle-90))
	
	# if start is negative and end is slightly positive, something probably went wrong
	if start_angle - 90 < 0 and end_angle-90 > 0 and end_angle-90 < 90:
		if verbose:
			Logger.mapgen_print("Negative start but positive end: " + str(start_angle-90) + " end: " + str(end_angle-90))
		# bring the end angle around
		end_angle = end_angle + 360
	
	#set the angles we wanted
	# road angles are in respect to X axis, so let's subtract 90 to point down Y
	road_node_right.get_child(0).get_child(0).start_angle = start_angle-90
	road_node_right.get_child(0).get_child(0).end_angle = end_angle-90
	
	node.add_child(road_node_right)
	return road_node_right
	
func set_straight_slope(loc, rot, node, i):
	var road_node = road_straight.instantiate()
	road_node.set_name("Road_instance "+str(i))
	# values here are experimental
	# set length
	var dist = 40 #loc.distance_to(loc2)
	road_node.relative_end = Vector3(0,0, dist)
	road_node.road_slope = 5.0
	
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
	
	#var spatial = Node3D.new()
	#spatial.set_name("Spatial0")
	node.add_child(road_node)
	#spatial.add_child(road_node)
	
	# place
	road_node.set_position(loc)
	
	# looking down -Z
	#var tg = to_global(loc2)
	#print("Look at target: " + str(tg))
	
	#road_node.look_at(tg, Vector3(0,1,0))
	# because we're pointing at +Z, sigh...
	#road_node.rotate_y(deg2rad(180))
	
	road_node.rotate_y(rot.y)
	return road_node

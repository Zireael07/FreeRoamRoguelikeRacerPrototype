@tool
extends Node3D

# class member variables go here, for example:
var draw
var road_straight
var road

var positions = []

var points_arc = []

var first_turn
var last_turn

var extend_turns = false

func _ready():
	draw = get_node(^"draw")
	road_straight = preload("res://roads/road_segment_straight.tscn")
	road = preload("res://roads/road_segment.tscn")


var lookup_names = { Vector3(0,0,10): "point one", Vector3(10,0,0) : "point two", Vector3(0,0,-10) : "point three", Vector3(-10,0,0) : "point four"}

func connect_intersections(one, two, verbose=false):
	if one > get_child_count() -1 or two > get_child_count() -1:
		Logger.mapgen_print("Wrong indices given: " + str(one) +", " + str(two))
		return false
	
	if not "point_one" in get_child(one) or not "point_one" in get_child(two):
		print("Targets are not intersections? " + String(get_child(one).get_name()) + " " + String(get_child(two).get_name()))
		return false
	
	Logger.mapgen_print("Connecting intersections " + String(get_child(one).get_name()) + " " + String(get_child(two).get_name()))
	
	var src_exit = get_src_exit(get_child(one), get_child(two), verbose)
	if src_exit == null:
		Logger.mapgen_print("No src exits found or left, abort")
		return false
	if verbose:
		Logger.mapgen_print("Src exit: " + str(src_exit) + " " + str(lookup_names[src_exit]))
	var loc_src_exit = to_local(get_child(one).to_global(src_exit))

	var dest_exit = get_dest_exit(get_child(one), get_child(two), verbose)
	
	if dest_exit == null:
		Logger.mapgen_print("No dest exits found or left, abort")
		return false
	if verbose:
		Logger.mapgen_print("Dest exit: " + str(dest_exit) + " " + str(lookup_names[dest_exit]))
	var loc_dest_exit = to_local(get_child(two).to_global(dest_exit))

	# debugging
	positions.append(loc_src_exit)
	positions.append(loc_dest_exit)
	#print("Line length: " + str(loc_dest_exit.distance_to(loc_src_exit)))
	
	# a sensible default
	var extend_factor = 3
#	if extend_turns:
#		extend_factor = extend_factor*1.5
		
	var extendeds = extend_lines(one,two, loc_src_exit, loc_dest_exit, extend_factor) #2.5) #2)
	var corner_points = get_corner_points(one,two, extendeds[0], extendeds[1], extendeds[0].distance_to(loc_src_exit))

	# make top node (which holds road name)
	var top_node = Node3D.new()
	top_node.set_script(load("res://roads/road_top.gd"))
	#print(str(one) + " to " + str(two))
	# this used to be child (node) id, but this way it's more intuitive
	# subtract 3 to get actual intersection number from child id
	top_node.set_name("Road " +str(one-3) + "-" + str(two-3))
	add_child(top_node)

	var data = calculate_initial_turn(corner_points[0], corner_points[1], loc_src_exit, extendeds[0], src_exit)
	initial_road_attempt(one, two, data, corner_points[0], top_node, verbose)

	data = calculate_last_turn(corner_points[2], corner_points[3], loc_dest_exit, extendeds[1], dest_exit)
	last_turn_attempt(one, two, data, corner_points[2], top_node, verbose)
	# FIXME: can't rely on corner points because this sometimes leads to holes even though the turn angles are correct
	set_straight(corner_points[1], corner_points[3], top_node)

# the length of the extend parameter here determines the radii of start and end turns
func extend_lines(one, two, loc_src_exit, loc_dest_exit, extend):
	#B-A: A->B
	var src_line = loc_src_exit-get_child(one).get_position()
	var loc_src_extended = src_line*extend + get_child(one).get_position()
	#debug_cube(loc_src_extended)
	
	var dest_line = loc_dest_exit-get_child(two).get_position()
	var loc_dest_extended = dest_line*extend + get_child(two).get_position()
	#debug_cube(loc_dest_extended)
	return [loc_src_extended, loc_dest_extended]
	
func get_corner_points(one, two, loc_src_extended, loc_dest_extended, dist):
	var corners = []
	
	# B-A = A-> B
	var vec_back = get_child(one).get_position() - loc_src_extended
	vec_back = vec_back.normalized()*dist # x units away
	
	var corner_back = loc_src_extended + vec_back
	corners.append(corner_back)
	#debug_cube(Vector3(corner_back.x, 1, corner_back.z))
	
	var vec_forw = loc_dest_extended - loc_src_extended
	vec_forw = vec_forw.normalized()*dist # x units away
	
	var corner_forw = loc_src_extended + vec_forw
	corners.append(corner_forw)
	#debug_cube(Vector3(corner_forw.x, 1, corner_forw.z))
	
	# the destinations
	# B-A = A-> B
	vec_back = get_child(two).get_position() - loc_dest_extended
	vec_back = vec_back.normalized()*dist # x units away
	
	corner_back = loc_dest_extended + vec_back
	corners.append(corner_back)
	#debug_cube(Vector3(corner_back.x, 1, corner_back.z))
	
	vec_forw = loc_src_extended - loc_dest_extended
	vec_forw = vec_forw.normalized()*dist # x units away
	
	corner_forw = loc_dest_extended + vec_forw
	corners.append(corner_forw)
	#debug_cube(Vector3(corner_forw.x, 1, corner_forw.z))
	
	return corners

# TODO: fold this and the next function into one?	
func calculate_initial_turn(corner1, corner2, loc_src_exit, loc_src_extended, src_exit):
	#B-A: A->B 
	# 3D has no tangent()
	var tang = (Vector2(corner1.x, corner1.z)-Vector2(loc_src_extended.x, loc_src_extended.z)).orthogonal()
	var tang2 = (Vector2(corner2.x, corner2.z)-Vector2(loc_src_extended.x, loc_src_extended.z)).orthogonal()
	
	# extend them
	var tang_factor = 100 # to cover absolutely everything
	
	tang = tang*tang_factor
	tang2 = tang2*tang_factor
	
	var start = Vector2(corner1.x, corner1.z) + tang
	
	#debug_cube(Vector3(start.x, 1, start.y))
	#positions.append(Vector3(start.x, 0, start.y))
	
	#var start = Vector2(corner1.x, corner1.z)
	var end = Vector2(corner1.x, corner1.z) - tang
	
	#debug_cube(Vector3(end.x, 1, end.y))
	#positions.append(Vector3(end.x, 0, end.y))
	
	#var start_b = Vector2(corner2.x, corner2.z)
	var start_b = Vector2(corner2.x, corner2.z) + tang2
	#debug_cube(Vector3(start_b.x, 1, start_b.y))
	#positions.append(Vector3(start_b.x, 0, start_b.y))
	var end_b = Vector2(corner2.x, corner2.z)-tang2
	#positions.append(Vector3(end_b.x, 0, end_b.y))
	#debug_cube(Vector3(end_b.x, 1, end_b.y))
	
	# check for intersection (2D only)
	var inters = Geometry2D.segment_intersects_segment(start, end, start_b, end_b)
	
	if inters:
		#print("Intersect: " + str(inters))
		#positions.append(Vector3(inters.x, 0, inters.y))
		#debug_cube(Vector3(inters.x, 1, inters.y))
	
		# radius = line from intersection to corner point
		var radius = inters.distance_to(Vector2(corner1.x, corner1.z))
	
		# the point to which 0 degrees corresponds
		var angle0 = inters+Vector2(radius,0)
	
		#debug_cube(Vector3(angle0.x, 1, angle0.y))
		#positions.append(Vector3(angle0.x, 0, angle0.y))
	
		var angles = get_node("/root/Geom").get_arc_angle(inters, Vector2(corner1.x, corner1.z), Vector2(corner2.x, corner2.z), angle0)
		# debug angles
		#positions.append(corner1)
		#positions.append(Vector3(angle0.x, 0, angle0.y))
		#positions.append(corner2)
			
		var points_arc = get_node("/root/Geom").get_circle_arc(inters, radius, angles[0], angles[1], true)
	
		# back to 3D
		#for i in range(points_arc.size()):
		#	positions.append(Vector3(points_arc[i].x, 0.01, points_arc[i].y))
		
		#positions.append(loc_dest_ex)	
	
		var fin = Vector3(points_arc[points_arc.size()-1].x, 0.01, points_arc[points_arc.size()-1].y)
	
		return [radius, angles[0], angles[1], fin] #Vector3(end_point.x, 0, end_point.y)]
	else:
		print("First turn, no inters detected")

func calculate_last_turn(corner1, corner2, loc_dest_exit, loc_dest_extended, dest_ex):
	#B-A: A->B 
	# 3D has no tangent()
	var tang = (Vector2(corner1.x, corner1.z)-Vector2(loc_dest_extended.x, loc_dest_extended.z)).orthogonal()
	var tang2 = (Vector2(corner2.x, corner2.z)-Vector2(loc_dest_extended.x, loc_dest_extended.z)).orthogonal()
	
	# extend them
	var tang_factor = 150 # to cover absolutely everything
	tang = tang*tang_factor
	tang2 = tang2*tang_factor
	var start = Vector2(corner1.x, corner1.z) + tang
	
	#debug_cube(Vector3(start.x, 1, start.y))
	
	#positions.append(Vector3(start.x, 0, start.y))
	
	#var start = Vector2(corner1.x, corner1.z)
	var end = Vector2(corner1.x, corner1.z) - tang
	
	#debug_cube(Vector3(end.x, 1, end.y))
	#positions.append(Vector3(end.x, 0, end.y))
	
	#var start_b = Vector2(corner2.x, corner2.z)
	var start_b = Vector2(corner2.x, corner2.z) + tang2
	#debug_cube(Vector3(start_b.x, 1, start_b.y))
	#positions.append(Vector3(start_b.x, 0, start_b.y))
	var end_b = Vector2(corner2.x, corner2.z)-tang2
	#positions.append(Vector3(end_b.x, 0, end_b.y))
	#debug_cube(Vector3(end_b.x, 1, end_b.y))
	
	# check for intersection (2D only)
	var inters = Geometry2D.segment_intersects_segment(start, end, start_b, end_b)
	
	if inters:
		#print("Intersect: " + str(inters))
		#debug_cube(Vector3(inters.x, 1, inters.y))
	
		var radius = inters.distance_to(Vector2(corner1.x, corner1.z))
		
		# the point to which 0 degrees corresponds
		var angle0 = inters+Vector2(radius,0)
		
		#debug_cube(Vector3(angle0.x, 1, angle0.y))
		
		var angles = get_node("/root/Geom").get_arc_angle(inters, Vector2(corner1.x, corner1.z), Vector2(corner2.x, corner2.z), angle0)
		# debug angles
		#positions.append(corner1)
		#positions.append(Vector3(angle0.x, 0, angle0.y))
		#positions.append(corner2)
	
		var points_arc = get_node("/root/Geom").get_circle_arc(inters, radius, angles[0], angles[1], true)
		
		# back to 3D
		#for i in range(points_arc.size()):
		#	positions.append(Vector3(points_arc[i].x, 0.01, points_arc[i].y))
	
		var fin = Vector3(points_arc[points_arc.size()-1].x, 0.01, points_arc[points_arc.size()-1].y)
	
	#positions.append(loc_dest_ex)	
		return [radius, angles[0], angles[1], fin] #Vector3(end_point.x, 0, end_point.y)]
	else:
		print("Last turn, no inters detected")
	
func initial_road_attempt(one, two, data, loc, node, verbose=false):
	if data == null:
		print("No first turn data, return")
		return
		
	var radius = data[0]
	var start_angle = data[1]
	var end_angle = data[2]
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

func last_turn_attempt(one, two, data, loc, node, verbose=false):
	if data == null:
		print("No last turn data, return")
		return
	
	var radius = data[0]
	var start_angle = data[1]
	var end_angle = data[2]
	
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

# -------------------------------------
# this is the meat of this whole script (selects the intersection exits so that we don't overlap/cross)
# assume standard rotation for now
func get_src_exit(src, dest, verbose=false):
	#print("X abs: " + str(abs(dest.get_translation().x - src.get_translation().x)))
	#print("Z abs: " + str(abs(dest.get_translation().z - src.get_translation().z)))
	
	var src_exits = src.open_exits
	
	if src_exits.size() < 1:
		#print("Error, no exits left")
		return
	else:
		if verbose:
			Logger.mapgen_print("available src exits: " + str(src_exits))
			Logger.mapgen_print("used exits" + str(src.used_exits))
		
	var rel_pos = src.to_local(dest.get_global_transform().origin)
	if verbose:
		Logger.mapgen_print("Src exits for relative pos: " + str(rel_pos) + " angle " + str(atan2(rel_pos.z, rel_pos.x)))
	
	
	# top = point_one, right = point_two, bottom = point_three, left = point_four
	# exits NEED to be listed CW (right = 2, bottom = 1 , top = 3, left = 4) if we sort by y
	# or CCW if sorted by angle?
	# left = 4 bottom = 1 right = 2 top = 3?
	
	#NE = quadrant 1 (we exclude top exit to avoid crossing over)
	if rel_pos.x > 0 and rel_pos.z > 0:
		if verbose:
			Logger.mapgen_print("Quadrant 1... angle: " + str(atan2(rel_pos.z, rel_pos.x)))
		if atan2(rel_pos.z, rel_pos.x) > 1:
			if src_exits.has(src.point_one):
				src_exits.remove_at(src_exits.find(src.point_one))
				src.used_exits[src.point_one] = 1 # quadrant
				return src.point_one
			elif src_exits.has(src.point_two):
				src_exits.remove_at(src_exits.find(src.point_two))
				src.used_exits[src.point_two] = 1 # quadrant
				return src.point_two
			else:
				print("No exits found for src quadrant 1!")
		else:
			if src_exits.has(src.point_two) and \
				src.used_exits.has(src.point_three) and src.used_exits[src.point_three] != 3:
				# extending doesn't quite work, so just forbid
				#if src.used_exits.has(src.point_three) and src.used_exits[src.point_three] == 3:
					#print("Extending turns...")
					#extend_turns = true
				src_exits.remove_at(src_exits.find(src.point_two))
				src.used_exits[src.point_two] = 1 #quadrant
				return src.point_two
			elif src_exits.has(src.point_one):
				src_exits.remove_at(src_exits.find(src.point_one))
				src.used_exits[src.point_one] = 1 #quadrant
				return src.point_one
			else:
				print("No exits found for src quadrant 1!")
	# NW - quadrant 2
	# same
	elif rel_pos.x < 0 and rel_pos.z > 0:
		if verbose:
			Logger.mapgen_print("Quadrant 2")
		# if angle is small, consider only bottom and right
		if atan2(rel_pos.z, rel_pos.x) < 2.5:
			if src_exits.has(src.point_one):
				src_exits.remove_at(src_exits.find(src.point_one))
				src.used_exits[src.point_one] = 2 #quadrant
				return src.point_one
			elif src_exits.has(src.point_two) and \
			src.used_exits[src.point_one] != 1:
				src_exits.remove_at(src_exits.find(src.point_two))
				src.used_exits[src.point_two] = 2 # quadrant
				return src.point_two
			elif src_exits.has(src.point_four) and \
			src.used_exits[src.point_one] != 2:
				src_exits.remove_at(src_exits.find(src.point_four))
				src.used_exits[src.point_four] = 2 # quadrant
				return src.point_four
			else:
				print("No exits found for src quadrant 2")
		else:
			if src_exits.has(src.point_one):
				src_exits.remove_at(src_exits.find(src.point_one))
				src.used_exits[src.point_one] = 2 # quadrant
				return src.point_one
			elif src_exits.has(src.point_three):
				src_exits.remove_at(src_exits.find(src.point_three))
				src.used_exits[src.point_three] = 2 # quadrant
				return src.point_three
			else:
				print("No exits found for src quadrant 2")
	# SE = quadrant 3 (exclude bottom exit)
	elif rel_pos.x > 0 and rel_pos.z < 0:
		if verbose:
			Logger.mapgen_print("Quadrant 3")
		if src_exits.has(src.point_three):
			src_exits.remove_at(src_exits.find(src.point_three))
			src.used_exits[src.point_three] = 3 #quadrant
			return src.point_three
		elif src_exits.has(src.point_two) and \
			src.used_exits.has(src.point_three) and src.used_exits[src.point_three] != 3:
			src_exits.remove_at(src_exits.find(src.point_two))
			src.used_exits[src.point_two] = 3 # quadrant
			return src.point_two
		else:
			print("No exits found for src quadrant 3")
	# SW = quadrant 4
	elif rel_pos.x < 0 and rel_pos.z < 0:
		if verbose:
			Logger.mapgen_print("Quadrant 4")
#		if src_exits.has(src.point_four):
#			src_exits.remove_at(src_exits.find(src.point_four))
#			print("Src exit 4 picked")
#			return src.point_four
#		el
		if src_exits.has(src.point_three):
			src_exits.remove_at(src_exits.find(src.point_three))
			src.used_exits[src.point_three] = 4 # quadrant
			return src.point_three
		elif src_exits.has(src.point_one):
			src_exits.remove_at(src_exits.find(src.point_one))
			src.used_exits[src.point_one] = 4 # quadrant
			return src.point_one
		else:
			print("No exits found for src quadrant 4")

# assume standard rotation for now
func get_dest_exit(src, dest, verbose=false):
	var dest_exits = dest.open_exits
	
	if dest_exits.size() < 1:
		#print("Error, no exits left")
		return
	else:
		if verbose:
			Logger.mapgen_print("available dest exits: " + str(dest_exits))
			Logger.mapgen_print("used exits" + str(dest.used_exits))
	
	var rel_pos = dest.to_local(src.get_global_transform().origin)
	if verbose:
		Logger.mapgen_print("Dest exits for relative pos: " + str(rel_pos) + " angle " + str(atan2(rel_pos.z, rel_pos.x)))
	
	# exits NEED to be listed CW (right = 2, bottom = 1, top = 3)
	# listed CCW if we sort by angle?
	# top = 3 right = 2 bottom = 1 
	
	# quadrant 4, exclude right exit to avoid crossing over
	if rel_pos.x < 0 and rel_pos.z < 0:
		if verbose:
			Logger.mapgen_print("Dest quadrant 4... " + str(atan2(rel_pos.z, rel_pos.x)))
		if atan2(rel_pos.z, rel_pos.x) > -2:
			if verbose:
				Logger.mapgen_print("Case 1")
			if dest_exits.has(dest.point_three):
				dest_exits.remove_at(dest_exits.find(dest.point_three))
				dest.used_exits[dest.point_three] = 4 # quadrant
				return dest.point_three
			elif dest_exits.has(dest.point_four):
				dest_exits.remove_at(dest_exits.find(dest.point_four))
				dest.used_exits[dest.point_four] = 4 # quadrant
				if verbose:
					Logger.mapgen_print("Picked exit 4")
				return dest.point_four
			elif dest_exits.has(dest.point_two):
				dest_exits.remove_at(dest_exits.find(dest.point_two))
				dest.used_exits[dest.point_two] = 4 # quadrant
				return dest.point_two
		else:
			if verbose:
				Logger.mapgen_print("Case 2")
			# additional requirement to prevent crossing over (for now)
			if atan2(rel_pos.z, rel_pos.x) < -2.5:
				if dest_exits.has(dest.point_four):
					dest_exits.remove_at(dest_exits.find(dest.point_four))
					dest.used_exits[dest.point_four] = 4 # quadrant
					if verbose:
						Logger.mapgen_print("Picked exit 4... " + str(atan2(rel_pos.z, rel_pos.x)))
					return dest.point_four
			
			if dest_exits.has(dest.point_three):
				dest_exits.remove_at(dest_exits.find(dest.point_three))
				dest.used_exits[dest.point_three] = 4 # quadrant
				return dest.point_three
			elif dest_exits.has(dest.point_one):
				dest_exits.remove_at(dest_exits.find(dest.point_one))
				dest.used_exits[dest.point_one] = 4 # quadrant
				return dest.point_one
	# quadrant 3, same
	elif rel_pos.x > 0 and rel_pos.z < 0:
		if verbose:
			Logger.mapgen_print("Dest quadrant 3")
		if dest_exits.has(dest.point_three):
			dest_exits.remove_at(dest_exits.find(dest.point_three))
			dest.used_exits[dest.point_three] = 3 # quadrant
			return dest.point_three
		elif dest_exits.has(dest.point_two) \
		and dest.used_exits.has(src.point_three) and dest.used_exits[src.point_three] != 3:
			dest_exits.remove_at(dest_exits.find(dest.point_two))
			dest.used_exits[dest.point_two] = 3 # quadrant
			return dest.point_two
		elif dest_exits.has(dest.point_four) \
		and dest.used_exits.has(src.point_three) and dest.used_exits[src.point_three] == 3:
			dest_exits.remove_at(dest_exits.find(dest.point_four))
			dest.used_exits[dest.point_four] = 3 # quadrant
			return dest.point_four
	# quadrant 2
	elif rel_pos.x < 0 and rel_pos.z > 0:
		if verbose:
			Logger.mapgen_print("Dest quadrant 2")
		if dest_exits.has(dest.point_one):
			dest_exits.remove_at(dest_exits.find(dest.point_one))
			dest.used_exits[dest.point_one] = 2 # quadrant
			return dest.point_one
		elif dest_exits.has(dest.point_three):
			dest_exits.remove_at(dest_exits.find(dest.point_three))
			dest.used_exits[dest.point_three] = 2 # quadrant
			return dest.point_three
	# quadrant 1, same
	elif rel_pos.x > 0 and rel_pos.z > 0:
		if dest_exits.has(dest.point_two):
			dest_exits.remove_at(dest_exits.find(dest.point_two))
			dest.used_exits[dest.point_two] = 1 # quadrant
			return dest.point_two
		elif dest_exits.has(dest.point_three):
			dest_exits.remove_at(dest_exits.find(dest.point_three))
			dest.used_exits[dest.point_three] = 1 # quadrant
			return dest.point_three


func draw_circle_arc(center, radius, angle_from, angle_to, right, clr):
	var points_arc = get_node("/root/Geom").get_circle_arc(center, radius, angle_from, angle_to, right)
	#print("Points: " + str(points_arc))


@tool
extends Node3D

# class member variables go here, for example:
var draw
var positions = []

var points_arc = []

var first_turn
var last_turn

var extend_turns = false

var data

func _ready():
	draw = get_node(^"draw")


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

	data = []
	data.resize(4)
	data[0] = calculate_turn(corner_points[0], corner_points[1], extendeds[0])
	# moved road nodes/meshing to a subclass
	#initial_road_attempt(one, two, data, corner_points[0], top_node, verbose)
	data[1] = corner_points[0]

	data[2] = calculate_turn(corner_points[2], corner_points[3], extendeds[1])
	#last_turn_attempt(one, two, data, corner_points[2], top_node, verbose)
	data[3] = corner_points[2]

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
	
func calculate_turn(corner1, corner2, loc_extended):
	#B-A: A->B 
	# 3D has no tangent()
	var tang = (Vector2(corner1.x, corner1.z)-Vector2(loc_extended.x, loc_extended.z)).orthogonal()
	var tang2 = (Vector2(corner2.x, corner2.z)-Vector2(loc_extended.x, loc_extended.z)).orthogonal()
	
	# extend them
	var tang_factor = 150 # to cover absolutely everything
	tang = tang*tang_factor
	tang2 = tang2*tang_factor
	
	var start = Vector2(corner1.x, corner1.z) + tang
	#debug_cube(Vector3(start.x, 1, start.y))
	#positions.append(Vector3(start.x, 0, start.y))

	var end = Vector2(corner1.x, corner1.z) - tang
	#debug_cube(Vector3(end.x, 1, end.y))
	#positions.append(Vector3(end.x, 0, end.y))

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
	
		var fin = Vector3(points_arc[points_arc.size()-1].x, 0.01, points_arc[points_arc.size()-1].y)
	
		return [radius, angles[0], angles[1], fin] #Vector3(end_point.x, 0, end_point.y)]
	else:
		print("Turn - no inters detected")

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


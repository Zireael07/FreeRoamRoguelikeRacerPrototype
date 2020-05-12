tool
extends Node2D

# class member variables go here, for example:
#scenes we're using
var road
var road_left
var road_straight

var dat

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	var start = OS.get_ticks_msec()
	
	road = preload("res://2d tests/curve_right_2d.tscn")
	road_left = preload("res://2d tests/curve_left_2d.tscn")
	road_straight = preload("res://2d tests/straight_2d.tscn")
	
	dat = loadData()
	
	makeRoads()
	
	var exec_time = OS.get_ticks_msec() - start
	print("Stored road generator execution time: " + String(exec_time))

	
# load data from json
func loadData():
	var savegame = File.new()
	var filename = get_name()
	var path_to_file = "roadsdata/"+filename+".json"
	
	var datas = []
	
	#check if a file with our name on it exists
	if not savegame.file_exists(path_to_file):
		#provide a default name
		path_to_file = "roadsdata/"+"Editor panel test"+".json"
	
	if savegame.file_exists(path_to_file):
		print("We have a data file")
		
		# Load the file line by line and process that dictionary to restore the object it represents		
		savegame.open(path_to_file, File.READ)

		var loadeddata = {} # dict.parse_json() requires a declared dict.
		#lines are counted from 1 not 0
		var linenum = 1
		while (!savegame.eof_reached()):
			#print("Parsing the file")
			var line = savegame.get_line()
			#skip empty lines
			if line.empty(): break
			
			loadeddata["game" + str(linenum)] = parseJson(line)
			datas.append(loadeddata["game"+str(linenum)])
			#print("Line is " + line)
			#print("Loaded data is : " + str(loadeddata["game"+str(linenum)]))
			
			linenum += 1
			
	savegame.close()
	return datas	

func parseJson(line):
	var result = {}
	result = parse_json(line)
	return result

# make the actual roads
func makeRoads():
	for linenum in range(0,dat.size()):
		#print(dat[linenum])
		#do our stuff
		#indexes start at 0
		var segment = setupRoad(linenum, dat[linenum])
		
		#if we're not the first, get previous
		if linenum > 0:
			makeNonFirst(linenum, segment)
		
		# we're first
		else:
			var curdata = dat[linenum]
			var cur_type = curdata["type"]
		
func makeNonFirst(linenum, segment):
	#print("We should be getting previous segment") #data")
	var prev = get_previous_segment(linenum)
	print("Previous segment is " + prev.get_name())
	var prev_loc = prev.get_position()
	
	#use data to determine whether it's a straight or a curve
	var data = dat[linenum-1]
#	print("Previous data is : " + str(data))
	var prev_type = data["type"]
	# do stuff
	if prev_type == "straight":
		var loc = get_end_location_straight(prev)
		print("Location is " + String(loc))
		
		#are we a curve?
		var curdata = dat[linenum]
		var cur_type = curdata["type"]
		
		# place
		if cur_type == "curved":
			segment.set_position(loc)
		else:
			segment.set_position(loc)
			
		#rotations	
		# the old method ported from 3d (a bit lengthy but takes into account the rotations)
		var needed_locs = vectors_to_fit_to_straight(segment, prev, curdata, data)
		var start_g = needed_locs[0]
		var check_loc = needed_locs[1]

		#var angle = rotate_to_fit_to_straight(loc, start_g, check_loc)
		#var angle = angle_data[0]
		var angle = rotate_to_fit(loc, start_g, check_loc)
		print("Angle to straight: " + str(angle))
		
		segment.set_rotation(angle)
		
		#if curdata["left_turn"] == false:
#			if rel_vector.x < 0:
#				print("We're rotating left")
#				#segment.set_rotation(angle)
#			else:
#				print("We're rotating right")
				#segment.set_rotation(-angle)
	
	#a curve
	else:
		var end_loc = prev.get_child(0).get_child(0).relative_end
		print("Previous segment is a curve at " + String(prev_loc) + " ending at " + String(end_loc))
		
		# signs are different for starting at 0,0 and not
		if prev_loc != Vector2(0,0):
			var loc = get_end_location_right_turn(prev, end_loc)
			
			print("Location is " + String(loc))
			
			#are we a curve?
			var curdata = dat[linenum]
			var cur_type = curdata["type"]
			
			# place
			if cur_type == "curved":
				segment.set_position(loc)
			else:
				segment.set_position(loc)
				
			#rotations
			var needed_locs = vectors_to_fit_to_curve(segment, prev, end_loc, curdata, data)
			var start_g = needed_locs[0]
			var check_loc = needed_locs[1]
			
			#var angle = rotate_to_fit_to_curve(loc, start_g, check_loc)
			var angle = rotate_to_fit(loc, start_g, check_loc)
			
			
			#check the angles (relative to segment)
			#var rel_target = segment.get_global_transform().xform_inv(g_target_loc)
			#print("Relative location of check vec to segment is " + String(rel_target))
			# swap because silly G3 conventions
			#var angle = atan2(rel_target.y, rel_target.x)
			
			print("[Straight] Angle to target loc is " + String(rad2deg(angle)) + " degrees")
			#to point straight, we need to rotate by 180-angle degrees
			#var rotate = -(deg2rad(180)-angle)
			
			segment.set_rotation(angle)
			
			
		# if starting at 0,0
		else:
			var loc = get_end_location_right_turn(prev, end_loc)
					
			print(str(linenum) + " location is " + String(-loc))
			
			#are we a curve?
			var curdata = dat[linenum]
			var cur_type = curdata["type"]
			
			# place
			if cur_type == "curved":
				if curdata["left_turn"] == false:
					segment.set_position(-(loc))
				else:
					segment.set_position(loc)
			else:
				segment.set_position(loc)


# setup		
func setupRoad(index, data):
	print("Setting up road for " + str(data))
	
	if data["type"] == "straight":
		print("Setting up a straight road")
		var node = setupStraightRoad(index, data)
		return node
	else:
		print("Setting up a curved road")
		var node = setupCurvedRoad(index, data)
		return node
	
func setupStraightRoad(index, data):
	var road_node = road_straight.instance()
	road_node.set_name("Road_instance" + String(index))
	
	if data["length"] > 0:
		road_node.length = data["length"]*20
	
	add_child(road_node)
	
	return road_node
	
func setupCurvedRoad(index, data):
	if data["left_turn"] == false:
		var road_node_right = road.instance()
		road_node_right.set_name("Road_instance" + String(index))
		#set the angle we wanted
		#if data["angle"] > 0:
		#	road_node_right.get_child(0).get_child(0).angle = data["angle"]
		#set the radius we wanted
		#if data["radius"] > 0:
		#	road_node_right.get_child(0).get_child(0).radius = data["radius"]
		add_child(road_node_right)
		return road_node_right
	else:
		var road_node_left = road_left.instance()
		road_node_left.set_name("Road_instance" + String(index))
		#if data["radius"] > 0:
		#	road_node_left.get_child(0).get_child(0).radius = data["radius"]
		add_child(road_node_left)
		return road_node_left
		
func get_previous_data(index, data):
	return data["game"+str(index-1)]
	
func get_current_data(index, data):
	return data["game"+str(index)]	
	
# utility
func get_previous_segment(index):
	if has_node("Road_instance"+String(index-1)): #get_node("Road_instance"+String(index-1)):
		return get_node("Road_instance"+String(index-1))
	
func get_current_segment(index):
	if has_node("Road_instance"+String(index)): #get_node("Road_instance"+String(index-1)):
		return get_node("Road_instance"+String(index))

# positioning
func get_end_location_straight(prev):
	var end_loc = prev.last
	#the relative end in global space
	var g_loc = prev.get_global_transform().xform(end_loc)
	#global space to local space
	var loc = get_global_transform().xform_inv(g_loc)
	return loc
	
# end_loc is the relative position, not absolute
func get_end_location_right_turn(prev, end_loc):
	#the 3D version has a minus sign here! (because of relative end's sign)
	var g_loc = prev.get_global_transform().xform(-end_loc)
	#print("Global location of relative end is: " + String(g_loc))
	var loc = get_global_transform().xform_inv(g_loc)
	return loc
	
#func get_start_vector(segment, data):
#	if data["type"] == "straight":
#		return segment.start_vector
#	else:
#		#return segment.get_child(0).get_child(0).start_vector
#		# for some reason the start vector is wrong for left turns, need to swap signs
#		if data["left_turn"] == false:
#			return segment.get_child(0).get_child(0).start_vector
#		else:
#			return -segment.get_child(0).get_child(0).start_vector
		
#func get_end_vector(segment, data):
#	if data["type"] == "straight":
#		return segment.end_vector
#	else:
#		#return segment.get_child(0).get_child(0).end_vector
#		# for some reason the start vector is wrong for left turns, need to swap signs
#		if data["left_turn"] == false:
#			return segment.get_child(0).get_child(0).end_vector
#		else:
#			return -segment.get_child(0).get_child(0).end_vector

# rotations (ported from 3d)

# 0. get point we want (endpoint of a vector)
# 1. get global position
# 2. convert it to our local space

func vectors_to_fit_to_straight(segment, prev, curdata, data):
	var target_loc = prev.end_ref
	#var target_loc = prev.last - get_end_vector(prev, data)
	#print("Target loc is " + String(target_loc))
	var g_target_loc = prev.get_global_transform().xform(target_loc)
	#print("Global target loc is " + String(g_target_loc))
	#make the global a local again but in our space
	var check_loc = get_global_transform().xform_inv(g_target_loc)
	#print("Check loc is " + str(check_loc))
	
	var start_vec = segment.get_child(0).get_child(0).start_ref #get_start_vector(segment, curdata)
	#print("Start vec: " + str(start_vec))
	# we need to be using the transform of what sets the ref (segment.get_child(0).get_child(0)!!!
	var g_start_vec = segment.get_child(0).get_child(0).get_global_transform().xform(start_vec)
	#print("Global start vec is " + str(g_start_vec))
	var start_g = get_global_transform().xform_inv(g_start_vec)
	#print("Start_g is " + str(start_g))
	
	return [start_g, check_loc]
	
#func rotate_to_fit_to_straight(loc, start_loc, check_loc):
#	#B-A = from a to b
#	var vector_curr = start_loc-loc
#	var vector_prev = check_loc-loc
#	var angle_prev = vector_curr.angle_to(vector_prev)
#
#	print("[Fit to straight] Angle to previous " + String(angle_prev) + " deg " + String(rad2deg(angle_prev)))
#
#	var angle = angle_prev
#
#	#var angle = deg2rad(180)-angle_prev
#	#print("Angle " + String(angle) + " deg " + String(rad2deg(angle)))
#
#	#need relative location of check_loc to start_loc
#	#var rel_vector = vector_curr+vector_prev
#	#print("Relative location of check to start vector is " + String(rel_vector))
#
#	return angle #[angle, rel_vector]

# 0. get point we want (endpoint of a vector)
# 1. get global position of vector
# 2. convert it to our local space
func vectors_to_fit_to_curve(segment, prev, end_loc, curdata, data):
	#print("Previous segment's end vector " + String(prev.end_vector))
	var target_loc = prev.get_child(0).get_child(0).end_ref
	#print("Target loc" + str(target_loc))
	#var target_loc = end_loc + get_end_vector(prev, data)
	var g_target_loc = prev.get_child(0).get_child(0).get_global_transform().xform(target_loc)
	#print("g_target_loc" + str(g_target_loc))
	
	#make the global a local again but in our space
	var check_loc = get_global_transform().xform_inv(g_target_loc)
	
	#print("Check loc is " + String(check_loc))
	#this is local
	var start_vec = segment.start_ref #get_start_vector(segment, curdata) 
	var g_start_vec = segment.get_global_transform().xform(start_vec)
	var start_g = get_global_transform().xform_inv(g_start_vec)
	
	return [start_g, check_loc]
	
#func rotate_to_fit_to_curve(loc, start_loc, check_loc):
#	#B-A = from a to b
#	var vector_curr = (start_loc-loc) #.normalized()*10
#	#print("Vector curr" + str(vector_curr))
#	var vector_prev = (check_loc-loc) #.normalized()*10
#	#print("Vector prev" + str(vector_prev))
#	var angle_prev = vector_curr.angle_to(vector_prev)
#
#	print("[Fit to curve] Angle to previous " + String(angle_prev) + " deg " + String(rad2deg(angle_prev)))
#
#	var angle = angle_prev
#
#	return angle
	
func rotate_to_fit(loc, start_loc, check_loc):
	#B-A = from a to b
	var vector_curr = (start_loc-loc) #.normalized()*10
	#print("Vector curr" + str(vector_curr))
	var vector_prev = (check_loc-loc) #.normalized()*10
	#print("Vector prev" + str(vector_prev))
	var angle_prev = vector_curr.angle_to(vector_prev)
	
	print("[Fit] Angle to previous " + String(angle_prev) + " deg " + String(rad2deg(angle_prev)))
	
	#var angle = angle_prev
	
	return angle_prev

tool
extends Position3D

# class member variables go here, for example:
#scenes we're using
var road
var road_left
var road_straight
export(int) var length_mult = 10

var dat

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	var start = OS.get_ticks_msec()
	
	road = preload("res://roads/road_segment.tscn")
	road_left = preload("res://roads/road_segment_left.tscn")
	road_straight = preload("res://roads/road_segment_straight.tscn")
	
	dat = loadData()
	
	makeRoads()
	
	var exec_time = OS.get_ticks_msec() - start
	print("Stored road generator execution time: " + String(exec_time))
	
	call_deferred("setNavMeshNew")
	#pass
	
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
			if cur_type == "straight":
				segment.updateGlobalVerts()

func makeNonFirst(linenum, segment):
	#print("We should be getting previous segment") #data")
	var prev = get_previous_segment(linenum)
	print("Previous segment is " + prev.get_name())
	var prev_loc = prev.get_translation()
	
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
			segment.set_translation(loc)
		else:
			segment.get_parent().set_translation(loc)
			segment.updateGlobalVerts()
			
		#rotations
		var needed_locs = vectors_to_fit_to_straight(segment, prev, dat[linenum])
		var start_g = needed_locs[0]
		var check_loc = needed_locs[1]
		
		var results = rotate_to_fit(loc, start_g, check_loc)
		var angle = results[0]
		var rel_loc = results[1]
		print("Angle to straight" + str(angle) + " " + str(rad2deg(angle)))
		
		#segment.set_rotation(Vector3(0,angle,0))
		if rel_loc.x > 0:
			segment.set_rotation(Vector3(0, angle,0))
		else:
			segment.set_rotation(Vector3(0, -angle,0))
		
	#a curve
	else:
		var end_loc = prev.get_child(0).get_child(0).relative_end

		print("Previous segment is a curve at " + String(prev_loc) + " ending at " + String(end_loc))
		# signs are different for starting at 0,0 and not
		if prev_loc != Vector3(0,0,0):
			var loc = get_end_location_right_turn(prev, end_loc)
			
			print("Location is " + String(loc))
			#are we a curve?
			var curdata = dat[linenum]
			var cur_type = curdata["type"]
			
			if cur_type == "curved":
				#print("Current type is curved")
				segment.set_translation(loc)
			else:
				#print("Current type is straight")
				segment.get_parent().set_translation(loc)
				segment.updateGlobalVerts()
			
			if cur_type == "straight":
				#rotations
				var needed_locs = vectors_to_fit_to_curve(segment, prev, end_loc, dat[linenum])
				var start_g = needed_locs[0]
				var check_loc = needed_locs[1]
				var g_target_loc = needed_locs[2]
				
				var results = rotate_to_fit(loc, start_g, check_loc)
				var angle = results[0]
				var rel_loc = results[1]
				print("Angle to target loc is " + String(rad2deg(angle)) + " degrees")
				
				if rel_loc.x > 0:
					segment.get_parent().set_rotation(Vector3(0, angle,0))
					segment.updateGlobalVerts()
				else:
					segment.get_parent().set_rotation(Vector3(0, -angle,0))
					segment.updateGlobalVerts()

			# curve
			else:
				# degrees
				var angle_diff = prev.get_child(0).get_child(0).end_angle - prev.get_child(0).get_child(0).start_angle
				segment.set_rotation_degrees(Vector3(0, -angle_diff, 0))
		
		#if starting at 0,0,0
		else:
			if data["left_turn"] == false:
				var loc = get_end_location_right_turn(prev, end_loc)
					
				print(str(linenum) + " location is " + String(-loc))
				#are we a curve?
				var curdata = dat[linenum] #get_current_data_new(linenum, dat)
				var cur_type = curdata["type"]
					
				if cur_type == "curved":
					if curdata["left_turn"] == false:
						#print("Current type is curved")
						segment.set_translation(-loc)
					else:
						segment.set_translation(loc)
						
					# rotations
					# degrees
					var angle_diff = prev.get_child(0).get_child(0).end_angle - prev.get_child(0).get_child(0).start_angle
					segment.set_rotation_degrees(Vector3(0, -angle_diff, 0))
						
				else:
					#print("Current type is straight")
					segment.get_parent().set_translation(-loc)
					segment.updateGlobalVerts()

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
	# set length
	if data["length"] > 0:
		road_node.length = data["length"]*length_mult
	
	var spatial = Spatial.new()
	spatial.set_name("Spatial"+String(index))
	add_child(spatial)
	spatial.add_child(road_node)
	return road_node
	
func setupCurvedRoad(index, data):
	if data["left_turn"] == false:
		var road_node_right = road.instance()
		road_node_right.set_name("Road_instance" + String(index))
		#set the angle we wanted
		#if data["angle"] > 0:
		#	road_node_right.get_child(0).get_child(0).angle = data["angle"]
		#set the radius we wanted
		if data["radius"] > 0:
			road_node_right.get_child(0).get_child(0).radius = data["radius"]
		add_child(road_node_right)
		return road_node_right
	else:
		var road_node_left = road_left.instance()
		road_node_left.set_name("Road_instance" + String(index))
		if data["radius"] > 0:
			road_node_left.get_child(0).get_child(0).radius = data["radius"]
		add_child(road_node_left)
		return road_node_left
		
func get_previous_data(index, data):
	return data["game"+str(index-1)]
	
func get_current_data(index, data):
	return data["game"+str(index)]
		
#func get_start_vector(segment, data):
#	#faster than checking if segment extends a custom script
#	if data["type"] == "straight":
#		return segment.start_vector
#	else:
#		return segment.get_child(0).get_child(0).start_vector

func get_end_location_straight(prev):
	#straights don't have children nodes because they don't need 'em
	#this is positive!!!
	var end_loc = prev.relative_end #- Vector3(0,0,0.5) #tiny fudge to hide imperfect rotations
	#the relative end in global space
	var g_loc = prev.get_global_transform().xform(end_loc)
	#global space to local space
	var loc = get_global_transform().xform_inv(g_loc)
	return loc
	
func get_end_location_right_turn(prev, end_loc):
	#var end_loc = prev.get_child(0).get_child(0).relative_end
	var g_loc = prev.get_global_transform().xform(-end_loc)
	#print("Global location of relative end is" + String(g_loc))
	var loc = get_global_transform().xform_inv(g_loc)
	return loc	

# rotations
# 0. get point we want (endpoint of a vector)
# 1. get global position
# 2. convert it to our local space

#functions to fit a curve to a straight
func vectors_to_fit_to_straight(segment, prev, data):
	var target_loc = prev.end_ref #prev.relative_end - prev.end_vector
	#print("Target loc is " + String(target_loc))
	var g_target_loc = prev.get_global_transform().xform(target_loc)
	print("Global target loc is " + String(g_target_loc))
	#make the global a local again but in our space
	var check_loc = get_global_transform().xform_inv(g_target_loc)
	
	var start_vec = segment.get_child(0).get_child(0).start_ref #get_start_vector(segment, data)
	var g_start_vec = segment.get_child(0).get_child(0).get_global_transform().xform(start_vec)
	var start_g = get_global_transform().xform_inv(g_start_vec)
	
	return [start_g, check_loc]

#functions to fit to a curve
func vectors_to_fit_to_curve(segment, prev, end_loc, data):
	#print("Previous segment's end vector " + String(prev.end_vector))
	var target_loc = prev.get_child(0).get_child(0).end_ref
	#print("Target loc: " + str(target_loc))
	var g_target_loc = prev.get_child(0).get_child(0).get_global_transform().xform(target_loc)
	#var target_loc = end_loc + prev.get_child(0).get_child(0).end_vector
	#negate (a curve's relative end is start-end)
	#var g_target_loc = prev.get_global_transform().xform(-target_loc)
	
	#make the global a local again but in our space
	var check_loc = get_global_transform().xform_inv(g_target_loc)
	
	print("Check loc is " + String(check_loc))
	#this is local
	var start_vec = segment.start_ref #get_start_vector(segment, data) 
	var g_start_vec = segment.get_parent().get_global_transform().xform(start_vec)
	var start_g = get_global_transform().xform_inv(g_start_vec)
	
	return [start_g, check_loc, g_target_loc]

func rotate_to_fit(loc, start_loc, check_loc):
	#B-A = from a to b
	var vector_curr = start_loc-loc
	var vector_prev = check_loc-loc
	var angle = vector_curr.angle_to(vector_prev)
	
	print("Angle to previous " + String(angle) + " deg " + String(rad2deg(angle)))
	
	#need relative location of check_loc to start_loc
	var rel_vector = vector_curr+vector_prev
	print("Relative location of check to start vector is " + String(rel_vector))
	
	return [angle, rel_vector]

# utility
func get_previous_segment(index):
	if has_node("Road_instance"+String(index-1)): #get_node("Road_instance"+String(index-1)):
		return get_node("Road_instance"+String(index-1))
	
	#handle the fact that the straight needs a spatial parent
	if has_node("Spatial"+String(index-1)+"/Road_instance"+String(index-1)):
		return get_node("Spatial"+String(index-1)+"/Road_instance"+String(index-1))
	
	if has_node("Spatial/Road_instance"+String(index-1)):
		return get_node("Spatial/Road_instance"+String(index-1))
	
func get_current_segment(index):
	if has_node("Road_instance"+String(index)): #get_node("Road_instance"+String(index-1)):
		return get_node("Road_instance"+String(index))
	
	#handle the fact that the straight needs a spatial parent
	if has_node("Spatial"+String(index)+"/Road_instance"+String(index)):
		return get_node("Spatial"+String(index)+"/Road_instance"+String(index))
	
	if has_node("Spatial/Road_instance"+String(index)):
		return get_node("Spatial/Road_instance"+String(index))

# navmesh
func fitNavMesh(straight, straight_ind, straight_ind2, curve, curve_ind, curve_ind2, left):
	print("Fitting navmesh " + curve.get_parent().get_parent().get_name() + " "+ str(curve_ind) + ", " + str(curve_ind2) + " to " + straight.get_name() + " " + str(straight_ind) + ", " + str(straight_ind2)) 
	if (straight != null and straight.global_vertices != null):
		var target1 = straight.global_vertices[straight_ind]
		var target2 = straight.global_vertices[straight_ind2]
		#print("Loaded road: target 1 is " + String(target1) + " target 2 is " + String(target2))

		# move the begin vertices to fit earlier straight
		#var curved = curve.get_child(0).get_child(0)
		var pos1 = curve.global_to_local_vert(target1)
#		#print("Local position of target 1 is: " + String(pos1))
		var pos2 = curve.global_to_local_vert(target2)
#		#print("Local position of target 2 is: " + String(pos2))
		#if (curved.nav_vertices != null):
		curve.move_key_navi_vertices(curve_ind, pos1, curve_ind2, pos2)
		#print("New vertices from loaded instancer, are : " + String(curved.nav_vertices[curved.nav_vertices.size()-2]) + " " + String(curved.nav_vertices[curved.nav_vertices.size()-1]))
#		
		curve.move_key_nav2_vertices(curve_ind, pos2, curve_ind2, pos1)

#		#create navmesh
		if left:
			curve.navMesh(curve.nav_vertices, true)
		
			#create other lane
			curve.navMesh(curve.nav_vertices2, false)
		else:
			curve.navMesh(curve.nav_vertices, false)
			#curve.navMesh(curve.nav_vertices, false)
			
			#create other lane
			curve.navMesh(curve.nav_vertices2, true)
#			
		curve.global_positions = curve.get_global_positions()


# make the navmeshes work
func setNavMeshNew():
	for linenum in range(0,dat.size()):
		#print(dat[linenum])
		#if we're not the first, get previous
		if linenum > 0:
			#use data to determine whether the previous is a straight or a curve
			var data = dat[linenum-1]
#			print("Previous data is : " + str(data))
			var prev_type = data["type"]
			
			if prev_type == "straight":
				#are we a curve?
				var curdata = dat[linenum] #get_current_data_new(linenum, dat)
				var cur_type = curdata["type"]
				
				if cur_type == "curved":
					if curdata["left_turn"] == true:
						#print("We should be getting previous segment") #data")
						var prev = get_previous_segment(linenum)
						print("Previous segment is " + prev.get_name() + " at " + str(prev.get_parent().get_translation()))
						
						#move the vertices so that the curve fits the straight
						var segment = get_current_segment(linenum)
						var curved = segment.get_child(0).get_child(0)
						if curved != null:
							fitNavMesh(prev, 2, 3, curved, curved.nav_vertices.size()-2, curved.nav_vertices.size()-1, true)

					#if we're turning right
					else:
						#print("We're turning right")
						var prev = get_previous_segment(linenum)
						print("Previous segment is " + prev.get_name() + " at " + str(prev.get_parent().get_translation()))
												
#						#move the vertices so that the curve fits the straight
						var segment = get_current_segment(linenum)
						var curved = segment.get_child(0).get_child(0)
						if curved != null:
							fitNavMesh(prev, 2, 3, curved, 0, 1, false)

			#if previous isn't a straight
			else:
				print("Segment " + str(linenum) + ", previous segment isn't a straight")
				#are we a curve?
				var curdata = dat[linenum]
				var cur_type = curdata["type"]
				
				if cur_type == "curved":
					var segment = get_current_segment(linenum)
					if (segment != null):
						print("Current segment is " + segment.get_name())
						var curved = segment.get_child(0).get_child(0)
						curved.navMesh(curved.nav_vertices, true)
						# create other lane
						curved.navMesh(curved.nav_vertices2, false)
					else:
						print("No current segment found")
		#if we're first
		else:
			#print("We're the first segment")
			#are we a curve?
			var curdata = dat[linenum]
			var cur_type = curdata["type"]
				
			if cur_type == "curved":
				var segment = get_current_segment(linenum)
				if (segment != null):
					#print("Current segment is " + segment.get_name())
					var curved = segment.get_child(0).get_child(0)
					curved.navMesh(curved.nav_vertices, true)
					# create other lane
					curved.navMesh(curved.nav_vertices2, false)
				#else:
					#print("No current segment found")
	
	# should iterate in reverse order to fix the other end of a curve
	for linenum in range(dat.size()-1, -1, -1):
		#print(str(linenum) + " " + str(dat[linenum]))
		var curdata = dat[linenum]
		var cur_type = curdata["type"]
		if linenum > 0:
			if cur_type == "straight":
				# is the previous one a curve?
				var data = dat[linenum-1]
#				print("Previous data is : " + str(data))
				var prev_type = data["type"]
				if prev_type == "curved":
					print("We ought to be getting previous segment for: " + str(linenum))
					var prev = get_previous_segment(linenum)
					print("Previous segment is " + prev.get_name() + " at " + str(prev.get_translation()))
					
					var cur = get_current_segment(linenum)
					print("Current segment is " + cur.get_name() + " at " + str(cur.get_parent().get_translation()))
					
					if data["left_turn"] == true:
						#move the vertices so that the curve fits the straight
						if cur != null:
							var curved = prev.get_child(0).get_child(0)
							if curved != null:
								fitNavMesh(cur, 0, 1, curved, 2, 3, true)
					else:
						print("We're turning right")
						#move the vertices so that the curve fits the straight
						if cur != null:
							var curved = prev.get_child(0).get_child(0)
							if curved != null:
								fitNavMesh(cur, 0, 1, curved, curved.nav_vertices.size()-1, curved.nav_vertices.size()-2, false)

				else:
					print("Previous segment is not a curve")
			else:
				print("Current segment is not a straight")

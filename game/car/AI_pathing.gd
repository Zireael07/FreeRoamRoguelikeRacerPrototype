extends Spatial

# class member variables go here, for example:
export(Vector3) var target = Vector3(0,0,0)
export(bool) var left = true # because Japan is LHD

var path
var end_ind
var last_ind
signal found_path
var road
var intersection

#var navigation_node
var map

# debugging
var draw
var draw_arc
var flip_mat = preload("res://assets/car/car_red.tres")
var debug = false

func _ready():
	# Called every time the node is added to the scene.
	
	#navigation_node = get_node("/root/root")
	# only traffic AI
	if is_in_group("AI"):
		map = get_node("/root/Navigation").get_node("map")
		
		# look up the closest intersection
		var map_loc = map.to_local(get_global_transform().origin)
		#print("global: " + str(get_global_transform().origin) + ", map_loc: " + str(map_loc))
		
		# this operates on child ids
		var sorted = map.sort_intersections_distance(map_loc, true)
		var closest_ind = sorted[0][1]
		
		#look_for_path(closest_ind, left)
		look_for_path_initial(closest_ind, left)
		
	# Initialization here
	if has_node("draw"):
		draw = get_node("draw")
	if has_node("draw2"):
		draw_arc = get_node("draw2")

func look_for_path_initial(start_ind, left):
	var closest = map.get_child(start_ind)
	#print("Closest int: " + closest.get_name() + " " + str(closest.get_translation()))

	# this operates on ids, therefore we subtract 3 from child id
	var int_paths = map.get_node("nav").get_paths(start_ind-3, -1)
	
	print("Paths: ", int_paths)
	
	var int_path = null
	# if only one path after we removed exclusions, just pick it
	if int_paths.size() == 1:
		int_path = int_paths[0]
	else:
		# get relative positions/angles
		var angles = []
		var tmp = []
		for p in int_paths:
			#TODO: a simpler way to do it?
			var rd_name = "Road "+str(p[0])+"-"+str(p[1])
			if not map.has_node(rd_name):
				# try the other way?
				rd_name = "Road " + str(p[1])+"-"+str(p[0])
			
			road = map.get_node(rd_name)
			# main part of the road
			var gl = road.get_node("Spatial0").get_global_transform().origin
			var rel_pos = get_node("BODY").get_global_transform().xform_inv(gl)
			#print(get_name() + ", rel pos for : ", rd_name, " - ", rel_pos)
			var angle = atan2(rel_pos.x, rel_pos.z)
			angles.append(abs(angle))
			tmp.append([abs(angle), p])
		# get the one with smallest relative angle
		angles.sort()
		#print("Angles: ", angles)
		
		if get_node("BODY") is VehicleBody:		
			# return the path
			for t in tmp:
				#print("Check t " + str(t))
				if t[0] == angles[0]:
					int_path = t[1]
		else:
			var id = angles.size()-1
			for t in tmp:
				if t[0] == angles[id]:
					int_path = t[1]
			
			
	print("[AI] our intersection path: " + str(int_path))
	
	# get road and direction
	var rd_name = "Road "+str(int_path[0])+"-"+str(int_path[1])
	var flip = false
	
	if not map.has_node(rd_name):
		# try the other way?
		rd_name = "Road " + str(int_path[1])+"-"+str(int_path[0])
		flip = true
	#print("Road name: " + rd_name)
	road = map.get_node(rd_name)
	#print("Road: " + str(road))
	
	var nav_data = map.get_node("nav").get_lane(road, flip, left)
	var nav_path = nav_data[0]

	path = traffic_reduce_path(nav_path, nav_data[1])
	last_ind = start_ind
	end_ind = int_path[1]
	emit_signal("found_path", [path, nav_data[1], nav_data[2]])
	
	# register with road
	road.AI_cars.append(self)
	#print(road.AI_cars)

# start_ind operates on child ids but exclude operates on intersection id
func look_for_path(start_ind, left_side, exclude=-1):
	#print("Looking for path, start_ind: " + str(start_ind) + ", exclude: " + str(exclude))
	var closest = map.get_child(start_ind)
	#print("Closest int: " + closest.get_name() + " " + str(closest.get_translation()))

	# this operates on ids, therefore we subtract 3 from child id
	var int_path = map.get_node("nav").get_path_look(start_ind-3, exclude)
			
	#print("[AI] our intersection path: " + str(int_path))
	
	# are we going back?
	var back = false
	if exclude == int_path[1]:
		back = true
	
	var lookup_path = map.get_node("nav").path_look[[int_path[0], int_path[1]]]
	#print("[AI] Lookup path: " + str(lookup_path))
	#var nav_path = map.get_node("nav").nav.get_point_path(lookup_path[0], lookup_path[1])
	#print("[AI] Nav path: " + str(nav_path))
	#print("Nav path length: " + str(nav_path.size()-1))
	
	#var tg_inters = map.get_child(int_path[1]+2) 
	#print("Target inters: " + tg_inters.get_name())
	var rd_name = "Road "+str(int_path[0])+"-"+str(int_path[1])
	var flip = false
	
	if not map.has_node(rd_name):
		# try the other way?
		rd_name = "Road " + str(int_path[1])+"-"+str(int_path[0])
		flip = true
	#print("Road name: " + rd_name)
	road = map.get_node(rd_name)
	#print("Road: " + str(road))
	
	var nav_data = map.get_node("nav").get_lane(road, flip, left_side)
	var nav_path = nav_data[0]
	
	var arc_pos = null
	var path_start = nav_path[0]
	var straight = null
	
	if exclude != -1:
		var pos = null
		# AI has no way ahead, has to go back the way it came
		# append at an offset if we're going back
		if back:
			# append intersection position
			pos = closest.get_global_transform().origin
			if left_side:
				# make use of the fact the intersections are never rotated
				pos = pos + Vector3(-4.0, 0.0, 0.0)
			else:
				pos = pos + Vector3(4.0, 0.0, 0.0)
		
		# if not going back, we're driving through an intersection
		else:
			#pos = null
			
#			var loc = get_node("BODY").to_local(nav_path[0])
#			# 2D angle to new target
#			var angle = atan2(loc.x, loc.z)
#			print("Angle to #1 of new road: ", angle)
#			if abs(angle) < 0.26:
#				pass # do nothing
			
			# are we going straight?
			straight = is_going_straight_across(closest, nav_path[0])
			if straight:
				pass # do nothing
			else:
				arc_pos = map.get_node("nav").intersection_arc(get_node("BODY"), closest, nav_path)
				if arc_pos != null:
					pos = null
				# just in case
				else:
					print(get_name(), " error, no arc!")
#					var x_off = loc.x
#					if x_off < 0: # right
#						pos = intersection_turn_offset(closest, pos, true)
#
#					else: # left
#						pos = intersection_turn_offset(closest, pos, false)
		
		if pos:			
			nav_path.insert(0, pos)
		
	
	
	#path = reduce_path(nav_path)
	path = traffic_reduce_path(nav_path, nav_data[1])
	
	# append arc_pos now if any
	if arc_pos != null:
		path = arc_pos + path
	
	last_ind = start_ind
	end_ind = int_path[1]
	emit_signal("found_path", [path, nav_data[1], nav_data[2]])
	
	# we're on an intersection until we reach path_start
	# if the intersection only has two exits in use, assume we can navigate easily
	if not back and closest.used_exits.size() > 2:
		var loc = get_node("BODY").to_local(path_start)
		var left_turn = false
		if loc.x < 0: # right
			left_turn = false
		else:
			left_turn = true
		intersection = closest
		#intersection.cars.append(self)
		intersection.cars[self] = [straight, left_turn]
		#print("Set " + get_name() + " as on intersection: ", closest.get_name())
	
	
	# register with road
	road.AI_cars.append(self)
	#print(road.AI_cars)

func is_going_straight_across(closest, target):
	var car = closest.to_local(get_node("BODY").get_global_transform().origin)
	var tg = closest.to_local(target)

	# debug
	#debug_cube(to_local(car+closest.get_global_transform().origin), true)
	#debug_cube(to_local(tg+closest.get_global_transform().origin), true)
	
	# snap car and loc to intersection points for simpler logic
	car = closest.snap_pos_to_points(car)
	target = closest.snap_pos_to_points(tg)
	#print("car: ", car, "tg: ", tg)
	
	# don't care about y
	car = Vector2(car.x, car.z)
	var angle = car.angle_to(Vector2(tg.x, tg.z))
	#print(get_name(), " angle to target: ", rad2deg(angle))
	
	var is_ahead = abs(angle) > deg2rad(120)	
	#print("Exit is ahead: ", is_ahead)
	
	return is_ahead

func intersection_turn_offset(closest, pos, right):
	# distance to intersection
	var rel_int = get_node("BODY").to_local(pos)
	var dist = rel_int.length()
	
	var sig = 1.0
	if right:
		sig = -1.0
	
	# this is relative to AI car
	var rel_loc = Vector3(sig*2.0, 0.0, dist-2.0)
	var off = get_node("BODY").get_global_transform().xform(rel_loc) 
	#print("off gl: ", off)
	#debug_cube(to_local(off), true)
	# now in closest intersection's space
	var int_loc_off = closest.to_local(off)
	#print("off loc: ", int_loc_off)
	# offset by local offset
	var mod_pos = pos + int_loc_off
	
	return mod_pos

func traffic_reduce_path(path, flip):
	var new_path = []
	# lots of magic numbers here, taken from setup_nav_astar() in map_nav.gd

	var to_keep
	# if we added an intersection, we need to keep point #1 too
	if path.size() > 66:
		to_keep = [0, 1, 17, 32]
	else:
		# curve midpoint, curve endpoint
		to_keep = [0, 16, 31] 

	# if tunnel, add midpoint 
	# IRL tunnels often have lower speed limits, and it also prevents the AI rubbing the wall
	if road.get_node("Spatial0/Road_instance 0").tunnel:
		#print("Road is tunnel")
		to_keep.append(path.size()-1)
		
	# other curve endpoint, some more...
	var to_keep_add
	# if we added an intersection, we need to keep point #1 too
	if path.size() > 66:
		to_keep_add = [34, 49, 50, 51, path.size()-2] #34+15
	else:
		to_keep_add = [33, 48, 49, 50, path.size()-4, path.size()-2] #33+15
		
	to_keep = to_keep + to_keep_add
	
	# to_keep is not necessarily in order because of midpoint above
	for id in range(to_keep.size()):
		if to_keep[id] in range(path.size()): # paranoia
			new_path.append(path[to_keep[id]])
		

			
	return new_path

func racer_reduce_path(path):
	var new_path = []
	# because we know how the path is set up, we can clean up spurious points w/o having to compare angles
	var to_keep = [0, 32, 48, path.size()-2]
	
	for i in range(path.size()):
		if i in to_keep:
			new_path.append(path[i])
			
	return new_path

# this one cuts corners
func reduce_path(path):
	var new_path = Array(path).duplicate() # can't iterate and remove
	print("Before reduce: " + str(new_path.size()))
			
	var to_remove = []
	# size()-1 is normal, deduce 2 so that i-2 works:
	for i in path.size()-3:
		# B-A = A to B
		var vec1 = path[i+1]-path[i]
		var vec2 = path[i+2]-path[i]
		var angle = vec2.angle_to(vec1) #radians
		#print("Angle diff " + str(rad2deg(angle)) + " for i: " + str(i))
		
		# if angle is the same, remove middle point
		if rad2deg(angle) < 0.01:
			#print("Removing point at: " + str(i+1) + " because angle is " + str(rad2deg(angle)))
			
			to_remove.append(path[i+1])
			# as we remove, the indices change
			#new_path.remove(i+1)
	
	# remove specified
	for p in to_remove:
		new_path.remove(new_path.find(p))
	
	
	#print("New path" + str(new_path))
	print("New path: " + str(new_path.size()))
		
	return new_path


func debug_cube(loc, red=false):
	var mesh = CubeMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance.new()
	node.set_mesh(mesh)
	if red:
		node.get_mesh().surface_set_material(0, flip_mat)
	node.set_cast_shadows_setting(0)
	if not red:
		node.add_to_group("debug")
	add_child(node)
	node.set_translation(loc)
	# offset to be visible above lane cubes
	node.translate(Vector3(0.0, 1.0, 0.0))
	
func clear_cubes():
	for c in get_children():
		if c.is_in_group("debug") and c.is_class("MeshInstance"):
			c.queue_free()

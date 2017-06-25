tool

extends "helpers.gd"

# class member variables go here, for example:
var m = FixedMaterial.new()
var points_center
var points_inner
var points_outer

var curve_one
var curve_two
var curve_three

#sidewalks
export(bool) var sidewalks = false
var points_inner_side
var points_outer_side

var curve_inner
var curve_outer

var road_height = 0.01

#road variables
export var lane_width = 2.5
export var radius = 15
export(Vector2) var loc = Vector2(0,0)
export(bool) var left_turn = false
export var angle = 120
export(int) var start_angle = null
export(int) var end_angle = null
#for matching the segments
var start_point
var last
var global_start
var global_end
var relative_end

#editor drawing
var positions  = Vector3Array()
var left_positions = Vector3Array()
var right_positions = Vector3Array()
var draw

#for minimap
var mid_point
var global_positions = Vector3Array()

var start_vector = Vector3()
var end_vector = Vector3()



#mesh material
export(FixedMaterial)    var material    = preload("res://assets/road_material.tres")
export(FixedMaterial) var sidewalk_material = preload("res://assets/cement.tres")

#props
var streetlight

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	draw = get_node("draw")
	#draw_debug_point(loc, Color(1,1,1))
	streetlight = preload("res://objects/streetlight.scn")
	
	points_center = get_circle_arc(loc, radius, get_start_angle(), get_end_angle())
	#how many points do we need debugged?
	var nb_points = 32
	
	#for index in range(nb_points):
		#draw_debug_point(points_center[index], Color(0, 0, 0))
		
	
	points_inner = get_circle_arc(loc, radius-lane_width, get_start_angle(), get_end_angle())
#	for index in range(nb_points):
#		draw_debug_point(points_inner[index], Color(0.5, 0.5, 0.5))
	
	points_outer = get_circle_arc(loc, radius+lane_width, get_start_angle(), get_end_angle())
#	for index in range(nb_points):
#		draw_debug_point(points_outer[index], Color(1, 0.5, 0.5))
	
	if sidewalks:
		points_inner_side = get_circle_arc(loc, radius-(lane_width*1.5), get_start_angle(), get_end_angle())
		points_outer_side = get_circle_arc(loc, radius+(lane_width*1.5), get_start_angle(), get_end_angle())
	
	make_curves()
	test_road()
	
	pass

func get_start_angle():
	var ret = 90-angle/2
	if (start_angle != null) and (start_angle > 0):
		return start_angle
	elif (end_angle != null) and (end_angle > 0):
		return end_angle - angle
	elif (angle > 0):
		return ret
	
func get_end_angle():
	var ret = 90+angle/2
	
	if (start_angle != null) and (start_angle > 0):
		##allow specifying both start and end angles
		if (end_angle != null) and (end_angle > 0):
			return end_angle
		else:
			return start_angle + angle
	elif (end_angle != null) and (end_angle > 0):
		return end_angle
	elif (angle > 0):
		return ret



func draw_debug_point(loc, color):
	addTestColor(m, color, null, loc.x, road_height, loc.y, 0.05,0.05,0.05)


func make_curve_for(array, node):
	var curve = Curve3D.new()
	var path = []
	var nb_points = 32
	
	if ((array != null) and array.size() > 0):
	
		for index in range(nb_points):
			path.append(array[index])
		
	if path.size() > 0:
		for point in path:
			curve.add_point(Vector3(point.x, road_height, point.y))
			
	node.set_curve(curve)
	
	#debug
	var get = node.get_curve()
	var num = get.get_point_count()
	#print("Number of points" + String(num))
	last = get.get_point_pos(num-1)
	#print("Position of last point is " + String(last))
	#addTestColor(m, Color(1,0,0), last.x, last.y, last.z, 0.1,0.1,0.1)
	
	return get

func make_curves():
	#create three path nodes
	var path_one = Path.new()
	var path_two = Path.new()
	var path_three = Path.new()
	
	path_one.set_name("path_one")
	path_two.set_name("path_two")
	path_three.set_name("path_three")
	
	add_child(path_one)
	add_child(path_two)
	add_child(path_three)
	
	curve_one = make_curve_for(points_center, path_one)
	curve_two = make_curve_for(points_inner, path_two)
	curve_three = make_curve_for(points_outer, path_three)

	if sidewalks:
		var path_four = Path.new()
		var path_five = Path.new()
		
		path_four.set_name("sidewalk_path")
		path_five.set_name("sidewalk_path2")
		
		add_child(path_four)
		add_child(path_five)
		
		curve_inner = make_curve_for(points_inner_side, path_four)
		curve_outer = make_curve_for(points_outer_side, path_five)

	#debug
	debug(path_one)
	
	#fix rotations
	if (!left_turn):
		set_rotation(Vector3(0,0,0))

	#fix issue
	if (get_parent().get_name() == "Placer"):
		#let the placer do its work
		get_parent().place_road()

func debug(path_one):
	var center_curve = path_one.get_curve()
	start_point = center_curve.get_point_pos(0)
	print("Position of start point is " + String(start_point))
	#addTestColor(m, Color(0, 1,0), "start_cube", start_point.x, start_point.y, start_point.z, 0.1, 0.1, 0.1)
	
	
	var num = center_curve.get_point_count()
	#print("Number of points" + String(num))
	last = center_curve.get_point_pos(num-1)
	print("Position of last point is " + String(last))
	
	var loc3d = Vector3(loc.x, 0, loc.y)
	if (left_turn):
		#transform so that we're at our start point
		#var trans = Vector3(-start_point.x, 0, -start_point.z)
		#set_translation(trans+loc3d)
	#else:
		set_rotation_deg(Vector3(0, -180, 0))
		#var trans = Vector3(start_point.x, 0, start_point.z)
		#set_translation(trans+loc3d)
	
	#global_end = get_global_transform().xform_inv(last)
	#global_start = get_global_transform().xform_inv(start_point)
	
	relative_end = start_point-last #global_start - global
	print("Last relative to start is " + String(relative_end))
	
	#test
	mid_point = center_curve.get_point_pos(round(num/2))
	
#make the sidewalk
func make_quad(index_one, index_two, inner):
	var right_side = null
	var left_side = null
	if inner:
		left_side = curve_two
		right_side = curve_inner
	else:
		left_side = curve_outer
		right_side = curve_three
	
	if (index_one != index_two):
			var start = right_side.get_point_pos(index_one)
			var left = left_side.get_point_pos(index_one)
			var ahead_right = right_side.get_point_pos(index_two)
			var ahead_left = left_side.get_point_pos(index_two)
#			
			#if (right):
			addRoadCurve(sidewalk_material, start, left, ahead_left, ahead_right, false)	

#make the mesh (less objects)
func make_strip_single(index_one, index_two, parent):
	var right_side = null
	var left_side = null
	var center_line = null
	
	center_line = curve_one
	left_side = curve_three
	right_side = curve_two
	

	if (left_side != null):
		if (index_one != index_two):
			var zero = right_side.get_point_pos(index_one)
			var one = center_line.get_point_pos(index_one)
			var two = center_line.get_point_pos(index_two)
			var three = right_side.get_point_pos(index_two)
			var four = left_side.get_point_pos(index_one)
			var five = left_side.get_point_pos(index_two)
			
			addRoadCurveTest(material, zero, one, two, three, four, five, parent)
						
		else:
			print("Bad indexes given")
	else:
		print("No sides given")


##make the mesh
func make_strip(index_one, index_two, right):
	var right_side = null
	var left_side = null

	if (right):
		right_side = curve_two
		left_side = curve_one
	else:
		right_side = curve_one
		left_side = curve_three
	
#note: right, left, right_ahead, left_ahead
	if (left_side != null):
		if (index_one != index_two):
			var start = right_side.get_point_pos(index_one)
			var left = left_side.get_point_pos(index_one)
			var ahead_right = right_side.get_point_pos(index_two)
			var ahead_left = left_side.get_point_pos(index_two)
#			
			if (right):
				addRoadCurve(material, start, left, ahead_left, ahead_right, false)
			else:
				addRoadCurve(material, start, left, ahead_left, ahead_right, true)
		else:
			print("Bad indexes given!")
	else:
		print("No sides given")

func get_global_positions():
	global_positions.push_back(get_global_transform().xform(positions[0]))
	global_positions.push_back(get_global_transform().xform(mid_point))
	global_positions.push_back(get_global_transform().xform(positions[31]))
		
	return global_positions

	
			
func test_road():
	#only mesh in game because meshing in editor can take >900 ms
	if not get_tree().is_editor_hint():
		#dummy to be able to get the road mesh faster
		var road_mesh = Spatial.new()
		road_mesh.set_name("road_mesh")
		add_child(road_mesh)
		
		#clear to prevent weird stuff
		positions.resize(0)
		left_positions.resize(0)
		right_positions.resize(0)
		global_positions.resize(0)
		
		var nb_points = 32
		for index in range(nb_points-1):
			make_strip_single(index, index+1, road_mesh)
			
			if sidewalks:
				make_quad(index, index+1, true)
				make_quad(index, index+1, false)
			
			positions.push_back(curve_one.get_point_pos(index))
			positions.push_back(curve_one.get_point_pos(index+1))
			left_positions.push_back(curve_three.get_point_pos(index))
			left_positions.push_back(curve_three.get_point_pos(index+1))
			right_positions.push_back(curve_two.get_point_pos(index))
			right_positions.push_back(curve_two.get_point_pos(index+1))
			
			#B-A = from a to b
			start_vector = Vector3(positions[1]-positions[0])
			end_vector = Vector3(positions[positions.size()-1] - positions[positions.size()-2])
			
		placeStreetlight()
	#draw an immediate line in editor instead
	else:
		#clear to prevent weird stuff
		positions.resize(0)
		left_positions.resize(0)
		right_positions.resize(0)
		
		var nb_points = 32
		for index in range(nb_points-1):
			positions.push_back(curve_one.get_point_pos(index))
			positions.push_back(curve_one.get_point_pos(index+1))
			left_positions.push_back(curve_three.get_point_pos(index))
			left_positions.push_back(curve_three.get_point_pos(index+1))
			right_positions.push_back(curve_two.get_point_pos(index))
			right_positions.push_back(curve_two.get_point_pos(index+1))
	
		#B-A = from a to b
		start_vector = Vector3(positions[1]-positions[0])
		end_vector = Vector3(positions[positions.size()-1] - positions[positions.size()-2])
		
		placeStreetlight()
	
		if (draw != null):
			draw.draw_line(positions)
			draw.draw_line(left_positions)
			draw.draw_line(right_positions)
			
#props
func placeStreetlight():
	var light = streetlight.instance()
	light.set_name("Streetlight")
	add_child(light)
	
	var num = (positions.size()/2)
	light.set_translation(positions[num]+Vector3(-5,0,0))
	
	if (not left_turn):
		light.set_rotation_deg(Vector3(0, 0, 0))
	else:
		light.set_rotation_deg(Vector3(0, 0, 0))
tool

extends "helpers.gd"

# class member variables go here, for example:
var m = FixedMaterial.new()
var points_center
var points_inner
var points_outer

# nav stuff
var points_inner_nav
var points_outer_nav

#sidewalks
export(bool) var sidewalks = false
var points_inner_side
var points_outer_side

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

#navmesh
var nav_vertices
var nav_vertices2
var global_vertices
var global_vertices2
# margin
var margin = 1
var left_nav_positions = Vector3Array()
var right_nav_positions = Vector3Array()

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
	points_inner_nav = get_circle_arc(loc, radius-lane_width+margin, get_start_angle(), get_end_angle())
	
	points_outer = get_circle_arc(loc, radius+lane_width, get_start_angle(), get_end_angle())
#	for index in range(nb_points):
#		draw_debug_point(points_outer[index], Color(1, 0.5, 0.5))
	points_outer_nav = get_circle_arc(loc, radius+lane_width-margin, get_start_angle(), get_end_angle())
	
	if sidewalks:
		points_inner_side = get_circle_arc(loc, radius-(lane_width*1.5), get_start_angle(), get_end_angle())
		points_outer_side = get_circle_arc(loc, radius+(lane_width*1.5), get_start_angle(), get_end_angle())
	
	fix_stuff()
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

	

func fix_stuff():
	#debug
	debug()
	
	#fix rotations
	if (!left_turn):
		set_rotation(Vector3(0,0,0))

	#fix issue
	if (get_parent().get_name() == "Placer"):
		#let the placer do its work
		get_parent().place_road()

func debug():
	start_point = Vector3(points_center[0].x, road_height, points_center[0].y) 
	print("Position of start point is " + String(start_point))
	#addTestColor(m, Color(0, 1,0), "start_cube", start_point.x, start_point.y, start_point.z, 0.1, 0.1, 0.1)

	last = Vector3(points_center[31].x, road_height, points_center[31].y)
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
	
	var mid_loc = points_center[(round(32/2))]
	mid_point = Vector3(mid_loc.x, road_height, mid_loc.y)
	
#make the sidewalk
func make_quad(index_one, index_two, inner):
	var right_side = null
	var left_side = null
	if inner:
		left_side = points_inner
		right_side = points_inner_side
	else:
		left_side = points_outer_side
		right_side = points_outer
	
	if (index_one != index_two):
			var start = Vector3(right_side[index_one].x, road_height, right_side[index_one].y)
			var left = Vector3(left_side[index_one].x, road_height, left_side[index_one].y)
			var ahead_right = Vector3(right_side[index_two].x, road_height, right_side[index_two].y)
			var ahead_left = Vector3(left_side[index_two].x, road_height, left_side[index_two].y)
#			
			#if (right):
			addRoadCurve(sidewalk_material, start, left, ahead_left, ahead_right, false)	

#make the mesh (less objects)
func make_strip_single(index_one, index_two, parent):
	var right_side = null
	var left_side = null
	var center_line = null
	
	center_line = points_center
	left_side = points_outer
	right_side = points_inner
	

	if (left_side != null):
		if (index_one != index_two):
			var zero = Vector3(right_side[index_one].x, road_height, right_side[index_one].y)
			var one = Vector3(center_line[index_one].x, road_height, center_line[index_one].y)
			var two = Vector3(center_line[index_two].x, road_height, center_line[index_two].y)
			var three = Vector3(right_side[index_two].x, road_height, right_side[index_two].y)
			var four = Vector3(left_side[index_one].x, road_height, left_side[index_one].y)
			var five = Vector3(left_side[index_two].x, road_height, left_side[index_two].y)
			
			
			addRoadCurveTest(material, zero, one, two, three, four, five, parent)
			
						
		else:
			print("Bad indexes given")
	else:
		print("No sides given")


#make the mesh
#func make_strip(index_one, index_two, right):
#	var right_side = null
#	var left_side = null
#
#	if (right):
#		right_side = curve_two
#		left_side = curve_one
#	else:
#		right_side = curve_one
#		left_side = curve_three
#	
#note: right, left, right_ahead, left_ahead
#	if (left_side != null):
#		if (index_one != index_two):
#			var start = right_side.get_point_pos(index_one)
#			var left = left_side.get_point_pos(index_one)
#			var ahead_right = right_side.get_point_pos(index_two)
#			var ahead_left = left_side.get_point_pos(index_two)
			
#			if (right):
#				addRoadCurve(material, start, left, ahead_left, ahead_right, false)
#			else:
#				addRoadCurve(material, start, left, ahead_left, ahead_right, true)
#		else:
#			print("Bad indexes given!")
#	else:
#		print("No sides given")

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
			
			positions.push_back(Vector3(points_center[index].x, road_height, points_center[index].y))
			positions.push_back(Vector3(points_center[index+1].x, road_height, points_center[index+1].y))
			left_positions.push_back(Vector3(points_outer[index].x, road_height, points_outer[index].y))
			left_positions.push_back(Vector3(points_outer[index+1].x, road_height, points_outer[index+1].y))
			right_positions.push_back(Vector3(points_inner[index].x, road_height, points_inner[index].y))
			right_positions.push_back(Vector3(points_inner[index+1].x, road_height, points_inner[index+1].y))
			#nav
			left_nav_positions.push_back(Vector3(points_outer_nav[index].x, road_height, points_outer_nav[index].y))
			left_nav_positions.push_back(Vector3(points_outer_nav[index+1].x, road_height, points_outer_nav[index+1].y))
			right_nav_positions.push_back(Vector3(points_inner_nav[index].x, road_height, points_inner_nav[index].y))
			right_nav_positions.push_back(Vector3(points_inner_nav[index+1].x, road_height, points_inner_nav[index+1].y))
			
			#B-A = from a to b
			start_vector = Vector3(positions[1]-positions[0])
			end_vector = Vector3(positions[positions.size()-1] - positions[positions.size()-2])
		
			
		#generate navi vertices
		nav_vertices = get_navi_vertices()
		nav_vertices2 = get_navi_vertices_alt()		
						
		placeStreetlight()
	#draw an immediate line in editor instead
	else:
		#clear to prevent weird stuff
		positions.resize(0)
		left_positions.resize(0)
		right_positions.resize(0)
		
		var nb_points = 32
		for index in range(nb_points-1):
			positions.push_back(Vector3(points_center[index].x, road_height, points_center[index].y))
			positions.push_back(Vector3(points_center[index+1].x, road_height, points_center[index+1].y))
			left_positions.push_back(Vector3(points_outer[index].x, road_height, points_outer[index].y))
			left_positions.push_back(Vector3(points_outer[index+1].x, road_height, points_outer[index+1].y))
			right_positions.push_back(Vector3(points_inner[index].x, road_height, points_inner[index].y))
			right_positions.push_back(Vector3(points_inner[index+1].x, road_height, points_inner[index+1].y))
	
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
		
# navmesh
func get_navi_vertices():
	var nav_vertices = Vector3Array()
	for index in range (positions.size()): #0 #1
		nav_vertices.push_back(positions[index]) #0 #2
		nav_vertices.push_back(right_nav_positions[index]) #1 #3
		
	return nav_vertices

func get_navi_vertices_alt():
	var nav_vertices = Vector3Array()
	for index in range (positions.size()): #0 #1
		nav_vertices.push_back(left_nav_positions[index]) #0 #2
		nav_vertices.push_back(positions[index]) #1 #3
		
	return nav_vertices

func make_navi(index, index_two, index_three, index_four):
	var navi = navQuad(index, index_two, index_three, index_four)
	return navi
	
func navQuad(one, two, three, four):
	var quad = []
	
	quad.push_back(one)
	quad.push_back(two)
	quad.push_back(three)
	quad.push_back(four)
	
	return quad

func makeNav(index, nav_mesh):
	var navi_poly = make_navi(index+1, index, index+2, index+3)
	nav_mesh.add_polygon(navi_poly)

func navMesh(vertices, left):
	#print("Making navmesh")
	var nav_polygones = []
	
	var nav_mesh = NavigationMesh.new()
	
	
	if (vertices.size() <= 0):
		nav_vertices = Vector3Array()
		nav_vertices.resize(0)
		
		#this gives us 124 nav vertices for left lane
		nav_vertices = get_navi_vertices()
	else:
		nav_vertices = vertices
		
	nav_mesh.set_vertices(nav_vertices)
	
	# skip every 4 verts
	for i in range(0,124,4):
		makeNav(i, nav_mesh)
	
	# add the actual navmesh and enable it
	var nav_mesh_inst = NavigationMeshInstance.new()
	nav_mesh_inst.set_navigation_mesh(nav_mesh)
	nav_mesh_inst.set_enabled(true)
	
	# assign lane
	if (left):
		nav_mesh_inst.add_to_group("left_lane")
		nav_mesh_inst.set_name("nav_mesh_left_lane_turn")
	else:
		nav_mesh_inst.add_to_group("right_lane")
		nav_mesh_inst.set_name("nav_mesh_right_lane_turn")
	
	add_child(nav_mesh_inst)

func get_key_navi_vertices():
	var key_nav_vertices = Vector3Array()
	key_nav_vertices.push_back(nav_vertices[0])
	key_nav_vertices.push_back(nav_vertices[1])
	key_nav_vertices.push_back(nav_vertices[nav_vertices.size()-1])
	key_nav_vertices.push_back(nav_vertices[nav_vertices.size()-2])
	
	return key_nav_vertices

func move_key_navi_vertices(index1, pos1, index2, pos2):
	nav_vertices.set(index1, pos1)
	#print("Setting vertex " + String(index1) + " to " + String(pos1))
	nav_vertices.set(index2, pos2)
	#print("Setting vertex " + String(index2) + " to " + String(pos2))
	#print("New vertices " + String(nav_vertices[index1]) + " & " + String(nav_vertices[index2]))
	
func move_key_nav2_vertices(index1, pos1, index2, pos2):
	nav_vertices2.set(index1, pos1)
	nav_vertices2.set(index2, pos2)
	
func global_to_local_vert(pos):
	return get_global_transform().xform_inv(pos)
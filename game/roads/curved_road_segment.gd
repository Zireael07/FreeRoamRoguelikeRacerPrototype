@tool
extends "helpers.gd" # this helper implements our own get_circle_arc for perf

# class member variables go here, for example:
var m = StandardMaterial3D.new()
var points_center
var points_inner
var points_outer

# nav stuff
var points_inner_nav
var points_outer_nav

#sidewalks
@export var sidewalks: bool = false
var points_inner_side
var points_outer_side

@export var barriers: bool = true
var points_outer_barrier
var barrier_quads = []

var road_height = 0.01

#road variables
@export var lane_width = 3
@export var radius = 15.0
@export var loc: Vector2 = Vector2(0,0)
@export var left_turn: bool = false
#export var angle = 120
@export var start_angle: int = 90
@export var end_angle: int = 180
#for matching the segments
var start_point
var last
var global_start
var global_end
var relative_end
var look_at_pos
var start_axis
var end_axis

#editor drawing
var positions  = PackedVector3Array()
var left_positions = PackedVector3Array()
var right_positions = PackedVector3Array()
var draw = null

# margin
var margin = 1.0
var left_nav_positions = PackedVector3Array()
var right_nav_positions = PackedVector3Array()

#for minimap
var mid_point
var global_positions = PackedVector3Array()

var start_vector = Vector3()
var end_vector = Vector3()
var start_ref
var end_ref



#mesh material
@export var material: Material = preload("res://assets/road_material.tres")
@export var sidewalk_material: Material = preload("res://assets/cement.tres")
@export var barrier_material: Material = preload("res://assets/barrier_material.tres")

#props
var streetlight

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	#add_to_group("roads")
	
	draw = get_node(^"draw")
	if has_node("Position3D"):
		look_at_pos = get_node(^"Position3D")
	
	#draw_debug_point(loc, Color(1,1,1))
	streetlight = preload("res://objects/streetlight.tscn")
	
	margin = float(lane_width)/2
	
	# angle fix
	if end_angle < 0:
		end_angle = 360+end_angle
	if start_angle < 0:
		start_angle = 360+start_angle
	
	
	points_center = get_circle_arc(loc, radius, start_angle, end_angle, not left_turn)
	#how many points do we need debugged?
	var nb_points = 32
	
	#for index in range(nb_points):
		#draw_debug_point(points_center[index], Color(0, 0, 0))
		
	
	points_inner = get_circle_arc(loc, radius-lane_width, start_angle, end_angle, not left_turn)
#	for index in range(nb_points):
#		draw_debug_point(points_inner[index], Color(0.5, 0.5, 0.5))
	points_inner_nav = get_circle_arc(loc, radius-lane_width+margin, start_angle, end_angle, not left_turn)
	
	points_outer = get_circle_arc(loc, radius+lane_width, start_angle, end_angle, not left_turn)
#	for index in range(nb_points):
#		draw_debug_point(points_outer[index], Color(1, 0.5, 0.5))
	points_outer_nav = get_circle_arc(loc, radius+lane_width-margin, start_angle, end_angle, not left_turn)
	
	if sidewalks:
		points_inner_side = get_circle_arc(loc, radius-(lane_width*1.5), start_angle, end_angle, not left_turn)
		points_outer_side = get_circle_arc(loc, radius+(lane_width*1.5), start_angle, end_angle, not left_turn)
		
	if barriers:
		points_outer_barrier = get_circle_arc(loc, radius+(lane_width*1.5)+0.5, start_angle, end_angle, not left_turn)
	
	
	var mid_loc = points_center[(round(32/2))]
	mid_point = Vector3(mid_loc.x, road_height, mid_loc.y)
	
	create_road()
	fix_stuff()
	
	# test
	var test_loc = Vector3(20, 0, 15)
	#var test_loc = Vector3(points_center[16].x, road_height, points_center[16].y)  #Vector3(10,0,10)
	debug_cube(test_loc)
	global_to_road_relative(get_global_transform() * test_loc)

#----------------------------------

#func get_start_angle():
#	var ret = 90-angle/2
#	if (start_angle != null) and (start_angle > 0):
#		return start_angle
#	elif (end_angle != null) and (end_angle > 0):
#		return end_angle - angle
#	elif (angle > 0):
#		return ret
#	
#func get_end_angle():
#	var ret = 90+angle/2
#	
#	if (start_angle != null) and (start_angle > 0):
#		##allow specifying both start and end angles
#		if (end_angle != null) and (end_angle > 0):
#			return end_angle
#		else:
#			return start_angle + angle
#	elif (end_angle != null) and (end_angle > 0):
#		return end_angle
#	elif (angle > 0):
#		return ret



#func draw_debug_point(loc, color):
#	super.addTestColor(m, color, null, loc.x, road_height, loc.y, 0.05,0.05,0.05)

	

func fix_stuff():
	#debug
	debug()
	
	#fix rotations
	#if (!left_turn):
	set_rotation(Vector3(0,0,0))

	#fix issue
	if (get_parent().get_name() == "Placer"):
		#let the placer do its work
		get_parent().place_road()

func debug():
	start_point = Vector3(points_center[0].x, road_height, points_center[0].y) 
	#Logger.road_print("Position of start point is " + String(start_point))
	#addTestColor(m, Color(0, 1,0), "start_cube", start_point.x, start_point.y, start_point.z, 0.1, 0.1, 0.1)

	last = Vector3(points_center[points_center.size()-1].x, road_height, points_center[points_center.size()-1].y)
	#Logger.road_print("Position of last point is " + String(last))
	
	#var loc3d = Vector3(loc.x, 0, loc.y)
	#if (left_turn):
		#transform so that we're at our start point
		#var trans = Vector3(-start_point.x, 0, -start_point.z)
		#set_translation(trans+loc3d)
	#else:
	#	set_rotation_deg(Vector3(0, -180, 0))
		#var trans = Vector3(start_point.x, 0, start_point.z)
		#set_translation(trans+loc3d)
	
	global_end = last * get_global_transform()
	global_start = start_point * get_global_transform()
	
	#global_end = last * get_global_transform()
	#global_start = start_point * get_global_transform()
	#relative_end = start_point-last 
	
	relative_end = global_start - global_end
	Logger.road_print("Last relative to start is " + var2str(relative_end))
	
	#var mid_loc = points_center[(round(32/2))]
	#mid_point = Vector3(mid_loc.x, road_height, mid_loc.y)
	
#make the sidewalk
#TODO: optimize to make two meshes instead of A LOT
func make_quad(index_one, index_two, inner):
	var right_side = null
	var left_side = null
	if inner:
		if (left_turn):
			left_side = points_inner_side
			right_side = points_inner
		else:
			left_side = points_inner
			right_side = points_inner_side
	else:
		if (left_turn):
			left_side = points_outer
			right_side = points_outer_side
		else:
			left_side = points_outer_side
			right_side = points_outer
	
	if (index_one != index_two):
			var start = Vector3(right_side[index_one].x, road_height, right_side[index_one].y)
			var left = Vector3(left_side[index_one].x, road_height, left_side[index_one].y)
			var ahead_right = Vector3(right_side[index_two].x, road_height, right_side[index_two].y)
			var ahead_left = Vector3(left_side[index_two].x, road_height, left_side[index_two].y)
#			
#			if (left_turn):
#				addRoadCurve(sidewalk_material, start, left, ahead_left, ahead_right, false)
#			else:
			# the final parameter flips uvs
			addRoadCurve(sidewalk_material, start, left, ahead_left, ahead_right, false)
			# to be two-sided :P
			addRoadCurve(sidewalk_material, left, start, ahead_right, ahead_left, false)

#make the mesh (less objects)
func make_strip_single(index_one, index_two, parent):
	var right_side = null
	var left_side = null
	var center_line = null

	# necessary to draw left turn since the arc turns the other way	
	if left_turn:
		center_line = points_center
		left_side = points_inner
		right_side = points_outer
	else:
		center_line = points_center #curve_one
		left_side = points_outer #curve_three
		right_side = points_inner #curve_two
	
	

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

func make_point_array(index_one, index_two):
	var right_side = null
	var left_side = null
	var center_line = null
	
	if left_turn:
		center_line = points_center
		left_side = points_inner
		right_side = points_outer
	else:
		center_line = points_center #curve_one
		left_side = points_outer #curve_three
		right_side = points_inner #curve_two
	

	if (left_side != null):
		if (index_one != index_two):
			var zero = Vector3(right_side[index_one].x, road_height, right_side[index_one].y) #right_side.get_point_pos(index_one)
			var one = Vector3(center_line[index_one].x, road_height, center_line[index_one].y) #center_line.get_point_pos(index_one)
			var two = Vector3(center_line[index_two].x, road_height, center_line[index_two].y) #center_line.get_point_pos(index_two)
			var three = Vector3(right_side[index_two].x, road_height, right_side[index_two].y) #right_side.get_point_pos(index_two)
			var four = Vector3(left_side[index_one].x, road_height, left_side[index_one].y) #left_side.get_point_pos(index_one)
			var five = Vector3(left_side[index_two].x, road_height, left_side[index_two].y) #left_side.get_point_pos(index_two)
			
			return [zero, one, two, three, four, five]
						
		else:
			print("Bad indexes given")
	else:
		print("No sides given")


func getQuads(array):
	var quad_one = [array[0], array[1], array[2], array[3], false]
	var quad_two = [array[1], array[4], array[5], array[2], true]
	
	return [quad_one, quad_two]

func optimizedmeshCreate(quads, material):
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance3D.new()
	node.set_name("plane")
	add_child(node)
	
	for qu in quads:
		addQuad(qu[0], qu[1], qu[2], qu[3], material, surface, qu[4])
	
	surface.generate_normals()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)
	
	# yay GD 3
	#node.create_convex_collision()


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
	global_positions.push_back(get_global_transform() * (start_point))
	global_positions.push_back(get_global_transform() * (mid_point))
	global_positions.push_back(get_global_transform() * (last))
	
	#global_positions.push_back(get_global_transform() * (positions[0]))
	#global_positions.push_back(get_global_transform() * (mid_point))
	#global_positions.push_back(get_global_transform() * (positions[31]))
		
	return global_positions

	
			
func create_road():
	
	#clear to prevent weird stuff
	positions.resize(0)
	left_positions.resize(0)
	right_positions.resize(0)
	global_positions.resize(0)
	
	var nb_points = 32
	
	for index in range(nb_points-1):
		positions.push_back(Vector3(points_center[index].x, road_height, points_center[index].y))
		positions.push_back(Vector3(points_center[index+1].x, road_height, points_center[index+1].y))
		left_positions.push_back(Vector3(points_outer[index].x, road_height, points_outer[index].y))
		left_positions.push_back(Vector3(points_outer[index+1].x, road_height, points_outer[index+1].y))
		right_positions.push_back(Vector3(points_inner[index].x, road_height, points_inner[index].y))
		right_positions.push_back(Vector3(points_inner[index+1].x, road_height, points_inner[index+1].y))
			
	# add the final position that we're missing
	positions.push_back(Vector3(points_center[points_center.size()-1].x, road_height, points_center[points_center.size()-1].y))
	left_positions.push_back(Vector3(points_outer[points_outer.size()-1].x, road_height, points_outer[points_outer.size()-1].y))
	right_positions.push_back(Vector3(points_inner[points_inner.size()-1].x, road_height, points_inner[points_inner.size()-1].y))
	
#	# to perfect the connection
#	if has_node("last_pos"):
#		get_node(^"last_pos").set_translation(positions[positions.size()-1])
#		get_node(^"last_pos").set_rotation(Vector3(0,0,0))
#		get_node(^"last_pos").rotate_object_local(Vector3(0,0,1), deg2rad(end_angle))
#		get_node(^"last_pos").translate_object_local(Vector3(0, 0, lane_width))
#
#	if has_node("last_pos2"):
#		get_node(^"last_pos2").set_translation(positions[positions.size()-1])
#		get_node(^"last_pos").set_rotation(Vector3(0,0,0))
#		get_node(^"last_pos2").rotate_object_local(Vector3(0,0,1), deg2rad(end_angle))
#		get_node(^"last_pos2").translate_object_local(Vector3(0,0, -lane_width))
#
#	if has_node("last_pos3"):
#		get_node(^"last_pos3").set_translation(positions[positions.size()-1])
	
	# 2D because 3D doesn't have tangent()
	var start_axis_2d = -(points_center[0]-loc).orthogonal().normalized()*10
	var end_axis_2d = -(points_center[points_center.size()-1]-loc).orthogonal().normalized()*10
		
	if left_turn:
		start_axis_2d = -start_axis_2d
		end_axis_2d = -end_axis_2d
		
	
	start_axis = Vector3(start_axis_2d.x, road_height, start_axis_2d.y)
	end_axis = Vector3(end_axis_2d.x, road_height, end_axis_2d.y)
		
	start_ref = positions[0]+start_axis
	end_ref = positions[positions.size()-1]+end_axis
	var inv_end_ref = positions[positions.size()-1]-end_axis
	
	#B-A = from a to b
	start_vector = (start_ref-positions[0])
	end_vector = (positions[positions.size()-1] - end_ref)
	
	
	#only mesh in game because meshing in editor can take >900 ms
	# we need meshes to bake navmesh
	if Engine.is_editor_hint() or not Engine.is_editor_hint():
		var quads = []
		#dummy to be able to get the road mesh faster
		#var road_mesh = Node3D.new()
		#road_mesh.set_name("road_mesh")
		#add_child(road_mesh)
		
		for index in range(nb_points-1):
			var array = make_point_array(index, index+1)
			quads.append(getQuads(array)[0])
			quads.append(getQuads(array)[1])
			
			#make_strip_single(index, index+1, road_mesh)
			
			if sidewalks:
				make_quad(index, index+1, true)
				make_quad(index, index+1, false)
				
			if barriers and index > 5 and index < 25:
				var barrier_array = make_barrier_array(index)
				var got = get_barrier_quads(barrier_array)
				barrier_quads.append(got[0])
				barrier_quads.append(got[1])
				#	make_barrier(index, barrier_material, node)
			
			#B-A = from a to b
			#start_vector = Vector3(positions[1]-positions[0])
			#end_vector = Vector3(positions[positions.size()-1] - positions[positions.size()-2])
		

		# add the final quad
		var array = make_point_array(points_center.size()-2, points_center.size()-1)
		quads.append(getQuads(array)[0])
		quads.append(getQuads(array)[1])
		
		#optimized mesh
		optimizedmeshCreate(quads, material)
		
		if barriers:
			# optimized barriers
			make_barrier(barrier_quads, barrier_material)
		
		placeStreetlight()
		
		# test merging
		# TODO: this is an easy way out, we need the mesh generated better
		if sidewalks:
			var splerger = Splerger.new()
			var mergelist = []

			for c in get_children():
				if String(c.name).find("road_curved") != -1:
					mergelist.append(c)

			# hide originals
			for m in mergelist:
				m.hide()

			splerger.merge_meshinstances(mergelist, self, true)
		
		# assign a more optimized collision shape :)
		var outline = Geometry2D.convex_hull(points_inner+points_outer)
		#print("curve outline: ", outline)
		# the existence of collision polygon is really good news for us
		var poly = get_node(^"StaticBody3D/CollisionPolygon3D").polygon
		poly = outline
		get_node(^"StaticBody3D/CollisionPolygon3D").set_polygon(poly)
		
		
	if not Engine.is_editor_hint():	
		# disable the emissiveness
		reset_lite()
		
	if not Engine.is_editor_hint():
		# kill debug draw in game
		draw.queue_free()
		
	#draw an immediate line in editor instead
	else:
		#B-A = from a to b
		#start_vector = Vector3(positions[1]-positions[0])
		#end_vector = Vector3(positions[positions.size()-1] - positions[positions.size()-2])
		
		placeStreetlight()
		# debug
		#var start_positions = [left_positions[0], positions[0], right_positions[0]]
		
		#var end_positions = [left_positions[positions.size()-1], positions[positions.size()-1], right_positions[positions.size()-1]]

	
		var debug_pos = [positions[0], Vector3(loc.x, road_height, loc.y)]
		var debug_inner = [right_positions[0], Vector3(loc.x, road_height, loc.y)]
		var debug_outer = [left_positions[0], Vector3(loc.x, road_height, loc.y)]
		
		var debug_pos2 = [positions[positions.size()-1], Vector3(loc.x, road_height, loc.y)]
		var debug_inner2 = [right_positions[right_positions.size()-1], Vector3(loc.x, road_height, loc.y)]
		var debug_outer2 = [left_positions[left_positions.size()-1], Vector3(loc.x, road_height, loc.y)]
		
		var debug_start_axis = [positions[0], start_ref]
		var debug_end_axis = [positions[positions.size()-1], end_ref]
	
#		if (draw != null):
#			draw.draw_line(positions)
#			draw.draw_line(left_positions)
#			draw.draw_line(right_positions)
			
			# debug
			#draw.draw_line(start_positions)
			#draw.draw_line(end_positions)
			
			
#			draw.draw_line(debug_pos)
#			draw.draw_line(debug_pos2)
#
#			draw.draw_line(debug_start_axis)
#			draw.draw_line(debug_end_axis)
			
			#draw.draw_line(debug_inner)
			#draw.draw_line(debug_inner2)
			
			#draw.draw_line(debug_outer)
			#draw.draw_line(debug_outer2)
		
#		if has_node("Position3D"):
#			#print("We have position marker")
#			#get_node(^"Position3D").set_translation(end_ref)
#			# because look_at() uses -Z not +Z!
#			get_node(^"Position3D").set_translation(inv_end_ref)
		
	
#props
func placeStreetlight():
	var light = streetlight.instantiate()
	light.set_name("Streetlight")
	add_child(light)
	
	var num = (positions.size()/2)
	var center = Vector3(0,0,0)
	
	# test
	#debug_cube(right_positions[num])
	#debug_cube(center)
	

	var dist = 2
	# B-A: A->B
	var dir = (center-right_positions[num])
	var offset = dir.normalized() * dist
	
	#var offset = Vector3(-2,0,0)
	
	# place
	#debug_cube(right_positions[num]+offset)
	light.set_position(right_positions[num]+offset)
	
#	# rotations
#	if (left_turn): #or abs(get_parent().get_parent().get_rotation_degrees().y) > 178:
#		light.set_rotation(Vector3(0,deg2rad(90),0))
#		#get_node(^"Debug").set_rotation_degrees(Vector3(0,90,0))
#	else:
#		light.set_rotation(Vector3(0,0,0))
#		#get_node(^"Debug").set_rotation_degrees(Vector3(0,0,0))

	#debug_cube(mid_point)

	light.look_at(get_global_transform() * mid_point, Vector3(0, 1, 0)) # this looks down -Z
	light.rotate_y(deg2rad(90)) # ... and we need +X

# visual barrier
func make_barrier_array(index):
	var one = Vector3(points_outer_barrier[index].x, road_height, points_outer_barrier[index].y)
	var two = Vector3(points_outer_barrier[index+1].x, road_height, points_outer_barrier[index+1].y)
	var three = Vector3(points_outer_barrier[index+1].x, 2, points_outer_barrier[index+1].y)
	var four = Vector3(points_outer_barrier[index].x, 2, points_outer_barrier[index].y)
	
	var flip = false
	if (!left_turn):
		flip = true
		
	return [one, two, three, four, flip]
	
func get_barrier_quads(array):
	var quad_one = [array[0], array[1], array[2], array[3], array[4]]
	var quad_two = [array[3], array[2], array[1], array[0], array[4]]
	
	return [quad_one, quad_two]


func make_barrier(quads, material):
	#Create a node building that will hold the mesh
	var node = MeshInstance3D.new()
	node.set_name("barrier")
	add_child(node)
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for qu in quads:
		addQuad(qu[0], qu[1], qu[2], qu[3], material, surface, qu[4])
	
	# outside
	#addQuad(one, two, three, four, material, surface, flip)
	# inside
	#addQuad(four, three, two, one, material, surface, flip)
	
	surface.generate_normals()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)

func global_to_local_vert(pos):
	return pos * get_global_transform()
	
func send_positions(map):
	#print(get_name() + " sending position to map")
	global_positions = get_global_positions()
	map.add_positions(global_positions)

func lite_up():
	#print("Lit up road")
	var material = get_node(^"plane").get_mesh().surface_get_material(0)
	material.set_shader_uniform("emission_energy", 3)
	material.set_shader_uniform("emission", Color(0,0,1))
	#material.set_feature(StandardMaterial3D.FEATURE_EMISSION, true)
	#material.set_emission(Color(0,0,1))
	
func reset_lite():
	#print("Reset lite")
	var material = get_node(^"plane").get_mesh().surface_get_material(0)
	material.set_shader_uniform("emission_energy", 0)
	#material.set_feature(StandardMaterial3D.FEATURE_EMISSION, false)

func rain_shine(rain_amount):
	var material = get_node(^"plane").get_mesh().surface_get_material(0)
	material.set_shader_uniform("roughness", 0.2)
	material.set_shader_uniform("metallic", 0.85)
	material.set_shader_uniform("puddle_size", rain_amount)
	
func no_rain():
	var material = get_node(^"plane").get_mesh().surface_get_material(0)
	material.set_shader_uniform("roughness", 1.0)
	material.set_shader_uniform("metallic", 0.0)
	material.set_shader_uniform("puddle_size", 0.0)
	#material.set_roughness(1.0)
	#material.set_metallic(0.0)
	
func debug_cube(loc):
	var mesh = BoxMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance3D.new()
	node.set_mesh(mesh)
	node.set_name("Debug")
	add_child(node)
	node.set_position(loc)
	node.set_cast_shadows_setting(0)


func _on_Area_body_entered(body):
	if body is CharacterBody3D:
		body.hit = self
	pass # Replace with function body.


func _on_Area_body_exited(body):
	if body is CharacterBody3D:
		body.hit = null
	pass # Replace with function body.

# https://web.archive.org/web/20160310163127/http://blogs.msdn.com/b/shawnhar/archive/2009/12/30/motogp-ai-coordinate-systems.aspx
func global_to_road_relative(gloc):
	var rel_loc = to_local(gloc)
	return local_to_road_relative(rel_loc)

func local_to_road_relative(loc):
	# what is our angle relative to curve's beginning
	var start_vec = Vector3(points_center[0].x, road_height, points_center[0].y) # this is always relative to the circle center, i.e. origin
	var angle = loc.angle_to(start_vec)+1e-06 #fudge
	print("angle: ", angle, ", deg: ", rad2deg(angle))
	
	# road relative position is how far along the track (x) and how far to the side (y)
	var max_angle = abs(end_angle-start_angle) # in degrees
	print("max angle: ", max_angle)
	# let's make our "along" between 0.0 (start) and 1.0 (end)
	var along = clamp(rad2deg(angle)/max_angle, 0.0, 1.0)
	# TODO: this could be made absolute by multiplying by curve length
	print("Along: ", along)
	
	# how far to the side?
	# find a point on the center line at along
	# a bit simplified but should work
	# can't lerp ints :(
	#var id = lerp(0, points_center.size()-1, along)
	var id = Tween.interpolate_value(0, points_center.size()-1, along, 1.0, Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	var cntr = Vector3(points_center[id].x, road_height, points_center[id].y)
	print("Center point for along: #", int(id), ", ", points_center[int(id)])
	
	var side = cntr.distance_to(loc)
	
	print("Road relative pos for ", loc, " : ", Vector2(along, side))
	return Vector2(along, side)
	

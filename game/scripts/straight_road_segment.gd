tool

extends "mesh_gen.gd"

# class member variables go here, for example:
export(Material)    var material    = preload("res://assets/road_material.tres")
var temp_positions = PoolVector3Array()

#editor drawing
var positions = PoolVector3Array()
var left_positions = PoolVector3Array()
var right_positions = PoolVector3Array()
var draw = null


var length = 5.0 # how many sections?
var roadwidth = 3
var sectionlength = 2
var roadheight = 0.01
export(float) var road_slope = 0.0

#sidewalks
export(bool) var sidewalks = false
var points_inner_side = PoolVector3Array()
var points_outer_side = PoolVector3Array()

export(bool) var guardrails = false
# debugging
var points_inner_rail = PoolVector3Array()
var points_outer_rail = PoolVector3Array()
# actual mesh
var rail_positions_left = PoolVector3Array()
var rail_positions_right = PoolVector3Array()

var support_positions = PoolVector3Array()

#for matching
var start_point = Vector3()
export(Vector3) var relative_end = Vector3(0,0,100)

#for minimap
var mid_point = Vector3()
var global_positions = PoolVector3Array()

#for rotations
var end_vector = Vector3()
var start_vector = Vector3()
var start_ref = Vector3()
var end_ref = Vector3()

export(bool) var trees = false
export(bool) var bamboo = false

## materials
var railing_tex = null
var cement_tex = null


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	#add_to_group("roads")
	
	draw = get_node("draw")
	
	railing_tex = preload("res://assets/railing_material.tres")
	cement_tex = preload("res://assets/cement.tres")	
	
	positions.resize(0) # = []
	left_positions.resize(0) # = []
	right_positions.resize(0) #= []

	points_inner_side.resize(0)
	points_outer_side.resize(0)

	points_inner_rail.resize(0)
	points_outer_rail.resize(0)
	
	#print("Positions: " + str(positions.size()))
	
	# calculate length
	length = (relative_end/sectionlength).z
	#print("Calculated length: " + str(length))
	
	#overdraw fix
	if (get_parent().get_name().find("Spatial") != -1):
		makeRoad()
		
	#place props
	get_node("Spatial").place_props(trees, bamboo, sectionlength*length)

func makeRoad():
	var quads = []
	#var support_quads = []
	var rail_quads = []
	
	# find out slope
	var slope_diff = road_slope/length
	#print("Slope diff" + str(slope_diff))

	#print("L: " + str(length) + " rounded " + str(int(length)) + " diff " + str(length-int(length)))
		
	for index in range(int(length)):
		#print("Index " + str(index))
		#clear the array
		temp_positions.resize(0)
		support_positions.resize(0)
		rail_positions_left.resize(0)
		rail_positions_right.resize(0)
		
		
		var start = Vector3(0,roadheight+(index*slope_diff),index*sectionlength)
		initSection(start, slope_diff)

		if slope_diff > 0:
			# one time for the whole road (!)
			makeSupport(start, slope_diff)
			#support_quads.append(getQuadsSimple(support_positions))
		

		#mesh
		#var num = temp_positions.size()
		#for index in range(num):
			#print("Index from temp_positions " + str(index))
			##draw_debug_point(positions[index], color)
		#only make the mesh in game (meshing in editor is hilariously slow, up to 900 ms)
		#if not Engine.is_editor_hint() or Engine.is_editor_hint():
			#meshCreate(temp_positions, material)
		
		quads.append(getQuads(temp_positions)[0])
		quads.append(getQuads(temp_positions)[1])

		positions.push_back(temp_positions[1])
		positions.push_back(temp_positions[2])
		left_positions.push_back(temp_positions[0])
		left_positions.push_back(temp_positions[3])
		right_positions.push_back(temp_positions[4])
		right_positions.push_back(temp_positions[5])
		
		if sidewalks:
			#print("We have sidewalks or guardrails, need more positions")
			points_inner_side.push_back(temp_positions[6])
			points_inner_side.push_back(temp_positions[7])
			points_outer_side.push_back(temp_positions[8])
			points_outer_side.push_back(temp_positions[9])
			
		
		if guardrails and not sidewalks:
			points_inner_rail.push_back(temp_positions[6])
			points_inner_rail.push_back(temp_positions[7])
			points_outer_rail.push_back(temp_positions[8])
			points_outer_rail.push_back(temp_positions[9])
		
			# guardrail quads
			rail_positions_left.push_back(temp_positions[6]) #0
			rail_positions_left.push_back(temp_positions[7]) #1
			rail_positions_left.push_back(temp_positions[3]) #2
			rail_positions_left.push_back(temp_positions[0]) #3
			
			rail_quads.append(getQuadsSimple(rail_positions_left))
		
			rail_positions_right.push_back(temp_positions[8]) #0
			rail_positions_right.push_back(temp_positions[9]) #1
			rail_positions_right.push_back(temp_positions[5]) #2
			rail_positions_right.push_back(temp_positions[4]) #3
			
			rail_quads.append(getQuadsSimple(rail_positions_right))
			
		# navmesh margin
		#left_nav_positions.push_back(temp_positions[6])
		#left_nav_positions.push_back(temp_positions[7])
		#right_nav_positions.push_back(temp_positions[8])
		#right_nav_positions.push_back(temp_positions[9])
		
		
		
	
	if Engine.is_editor_hint() or not Engine.is_editor_hint():
		#setupNavi(self)

		# road cap		
		if length-int(length) > 0:
			roadCap((length-int(length)), cap_quads, slope_diff)
		
		optimizedmeshCreate(quads, cap_quads, material)
		
		# bonus stuffs
		if support_positions.size() > 0:
			#optimizedmeshCreate(support_quads, building_tex1)
			var array = support_positions
			var surface = SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)

			#Create a node that will hold the mesh
			var node = MeshInstance.new()
			node.set_name("support")
			add_child(node)

			# cement material is one sided for now
			addQuad(array[0], array[1], array[2], array[3], cement_tex, surface, false)
			addQuad(array[3], array[2], array[1], array[0], cement_tex, surface, false)
			
			# other side
			addQuad(array[4], array[5], array[6], array[7], cement_tex, surface, false)
			addQuad(array[7], array[6], array[5], array[4], cement_tex, surface, false)
			

			#Set the created mesh to the node
			node.set_mesh(surface.commit())
		
		if rail_quads.size() > 0:
			var surface = SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)

			#Create a node building that will hold the mesh
			var node = MeshInstance.new()
			node.set_name("guardrail")
			add_child(node)
		
			var uvs = [Vector2(0,0), Vector2(0,1), Vector2(1,1), Vector2(1,0)]
		
			for qu in rail_quads:
				addQuadCustUV(qu[0], qu[1], qu[2], qu[3], uvs[1], uvs[2], uvs[3], uvs[0], railing_tex, surface) #, qu[4])
				addQuadCustUV(qu[3], qu[2], qu[1], qu[0], uvs[0], uvs[3], uvs[2], uvs[1], railing_tex, surface) #, qu[4])
				# 3 2 1 0

			surface.generate_normals()

			surface.index()
			
			#Set the created mesh to the node
			node.set_mesh(surface.commit())
			
			#Turn off shadows
			node.set_cast_shadows_setting(0)
			
			# yay GD 3
			#node.create_convex_collision()
			node.create_trimesh_collision()
		
	if not Engine.is_editor_hint():
		# disable the emissiveness
		reset_lite()
			
	
	#debug midpoint
	if positions.size() > 0:
		var middle = round(positions.size()/2)
		mid_point = positions[middle]
	
	#global positions
	if positions.size() > 0:
		global_positions = get_global_positions()
		
		start_vector = (positions[1] - positions[0])
		#B-A = from a to b
		end_vector = (positions[positions.size()-1]- positions[positions.size()-2])
		
		start_ref = positions[0]+start_vector
		end_ref = positions[positions.size()-1]+end_vector
	
	#in editor, we draw simple immediate mode lines instead
	if Engine.is_editor_hint():
		if positions.size() > 0:
			var debug_start_axis = [positions[0], start_ref]
			var debug_end_axis = [positions[positions.size()-1], end_ref]
			
			
			#debug drawing
			draw.draw_line(positions)
			draw.draw_line(left_positions)
			draw.draw_line(right_positions)
			draw.draw_line(debug_start_axis)
			draw.draw_line(debug_end_axis)
			if points_inner_side.size() > 0:
				draw.draw_line(points_inner_side)
				draw.draw_line(points_outer_side)
				
			if points_inner_rail.size() > 0:
				draw.draw_line(points_inner_rail)
				draw.draw_line(points_outer_rail)
	
	# kill debug draw in game
	else:
		draw.queue_free()

func initSection(start, slope):
	var start_height = start.y
	var end_height = start.y + slope
#	if slope > 0:
#		print("Start height " + str(start_height) + " end height" + str(end_height))
	
	#init positions
	temp_positions.push_back(Vector3(start.x-roadwidth, start_height, start.z))
	temp_positions.push_back(start)
	temp_positions.push_back(Vector3(0, end_height, start.z+sectionlength))
	temp_positions.push_back(Vector3(start.x-roadwidth, end_height, start.z+sectionlength))
	temp_positions.push_back(Vector3(start.x+roadwidth, start_height, start.z))
	temp_positions.push_back(Vector3(start.x+roadwidth, end_height, start.z+sectionlength))
	
	# sides
	if sidewalks:
		var width_with_side = roadwidth*1.25
		
		temp_positions.push_back(Vector3(start.x-width_with_side, start_height, start.z))
		temp_positions.push_back(Vector3(start.x-width_with_side, end_height, start.z+sectionlength))
		temp_positions.push_back(Vector3(start.x+width_with_side, start_height, start.z))
		temp_positions.push_back(Vector3(start.x+width_with_side, end_height, start.z+sectionlength))
	
	if guardrails:
		temp_positions.push_back(Vector3(start.x-roadwidth, start_height + 1, start.z))
		temp_positions.push_back(Vector3(start.x-roadwidth, end_height + 1, start.z+sectionlength))
		temp_positions.push_back(Vector3(start.x+roadwidth, start_height + 1, start.z))
		temp_positions.push_back(Vector3(start.x+roadwidth, end_height + 1, start.z + sectionlength))
	
	
	# navmesh (#6-9)
	#temp_positions.push_back(Vector3(start.x-roadwidth+margin, start_height, start.z))
	#temp_positions.push_back(Vector3(start.x-roadwidth+margin, end_height, start.z+sectionlength))
	#temp_positions.push_back(Vector3(start.x+roadwidth-margin, start_height, start.z))
	#temp_positions.push_back(Vector3(start.x+roadwidth-margin, end_height, start.z+sectionlength))
	
	
	

func makeSupport(start, slope):
	var start_height = start.y
	var end_height = start.y + slope
	
	# one side
	support_positions.push_back(Vector3(start.x-roadwidth, start_height, start.z)) #3
	support_positions.push_back(Vector3(start.x-roadwidth, end_height, start.z+sectionlength)) #2
	support_positions.push_back(Vector3(start.x-roadwidth, 0, start.z+sectionlength)) #1
	support_positions.push_back(Vector3(start.x-roadwidth, 0, start.z)) #0
	
	# other side
	support_positions.push_back(Vector3(start.x+roadwidth, 0, start.z))
	support_positions.push_back(Vector3(start.x+roadwidth, 0, start.z+sectionlength))
	support_positions.push_back(Vector3(start.x+roadwidth, end_height, start.z+sectionlength))
	support_positions.push_back(Vector3(start.x+roadwidth, start_height, start.z))

func get_global_positions():
	global_positions = []
	global_positions.push_back(get_global_transform().xform(positions[0]))
	global_positions.push_back(get_global_transform().xform(mid_point))
	global_positions.push_back(get_global_transform().xform(positions[positions.size()-2]))
	global_positions.push_back(get_global_transform().xform(positions[positions.size()-1]))
		
	return global_positions

func getQuadsSimple(array):
	var quad_one = [array[0], array[1], array[2], array[3], false]
	
	return quad_one

func getQuads(array):
	var quad_one = [array[0], array[1], array[2], array[3], false]
	var quad_two = [array[1], array[4], array[5], array[2], true]
	
	return [quad_one, quad_two]

func optimizedmeshCreate(quads, material):
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("plane")
	add_child(node)
	
	for qu in quads:
		addQuad(qu[0], qu[1], qu[2], qu[3], material, surface, qu[4])
	
	surface.generate_normals()
	
	surface.index()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)
	
	# yay GD 3
	node.create_convex_collision()

func meshCreate(array, material):
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("plane")
	add_child(node)
	
	addQuad(array[0], array[1], array[2], array[3], material, surface, false)
	addQuad(array[1], array[4], array[5], array[2], material, surface, true)
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)

func global_to_local_vert(pos):
	return get_global_transform().xform_inv(pos)
	
func send_positions(map):
	if positions.size() < 1:
		return
	#print(get_name() + " sending position to map")
	global_positions = get_global_positions()
	map.add_positions(global_positions)
	
func lite_up():
	#print("Lit up road")
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_shader_param("emission_energy", 3)
	material.set_shader_param("emission", Color(0,0,1))
	#material.set_feature(SpatialMaterial.FEATURE_EMISSION, true)
	#material.set_emission(Color(0,0,1))
	
func reset_lite():
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_shader_param("emission_energy", 0)
	#material.set_feature(SpatialMaterial.FEATURE_EMISSION, false)
	
func rain_shine():
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_roughness(0.2)
	material.set_metallic(0.85)
	
func no_rain():
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_shader_param("roughness", 1.0)
	material.set_shader_param("metallic", 0.0)
	#material.set_roughness(1.0)
	#material.set_metallic(0.0)

tool

extends "mesh_gen.gd"

# class member variables go here, for example:
var m = SpatialMaterial.new()
var color = Color(1,0,0)
export(SpatialMaterial)    var material    = preload("res://assets/road_material.tres")
var temp_positions = PoolVector3Array()

#editor drawing
var positions = PoolVector3Array()
var left_positions = PoolVector3Array()
var right_positions = PoolVector3Array()
var draw


export(int) var length = 5
var roadwidth = 3
var sectionlength = 2
var roadheight = 0.01

#for matching
var start_point
export(Vector3) var relative_end

#navigation mesh
var nav_vertices
var global_vertices
var nav_vertices_alt
var global_vertices_alt
# margin
var margin = 1
var left_nav_positions = PoolVector3Array()
var right_nav_positions = PoolVector3Array()

#for minimap
var mid_point
var global_positions = PoolVector3Array()

#for rotations
var end_vector
var start_vector

#props
var building
var buildDistance = 10
var numBuildings = 10

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	#add_to_group("roads")
	
	draw = get_node("draw")
	
	#props
	building = preload("res://objects/skyscraper.tscn")
	
	var quads = []
	
	#overdraw fix
	if (get_parent().get_name().find("Spatial") != -1):
		for index in range(length):
			#clear the array
			temp_positions.resize(0)
			var start = Vector3(0,roadheight,index*sectionlength)
			initSection(start)
	
			#mesh
			var num = temp_positions.size()
			for index in range(num):
				##draw_debug_point(positions[index], color)
				#only make the mesh in game (meshing in editor is hilariously slow, up to 900 ms)
				if not Engine.is_editor_hint():
					#meshCreate(temp_positions, material)
					quads.append(getQuads(temp_positions)[0])
					quads.append(getQuads(temp_positions)[1])
				
				positions.push_back(temp_positions[1])
				positions.push_back(temp_positions[2])
				left_positions.push_back(temp_positions[0])
				left_positions.push_back(temp_positions[3])
				right_positions.push_back(temp_positions[4])
				right_positions.push_back(temp_positions[5])
				# navmesh margin
				left_nav_positions.push_back(temp_positions[6])
				left_nav_positions.push_back(temp_positions[7])
				right_nav_positions.push_back(temp_positions[8])
				right_nav_positions.push_back(temp_positions[9])
		
		# set up navmesh if not in editor	
		if not Engine.is_editor_hint():
			setupNavi(self)
			optimizedmeshCreate(quads, material)
				
	#set the end
	relative_end = Vector3(0,0, sectionlength*length)
	
	#debug midpoint
	if positions.size() > 0:
		var middle = round(positions.size()/2)
		mid_point = positions[middle]
	
	#global positions
	if positions.size() > 0:
		global_positions = get_global_positions()
		
		start_vector = Vector3(positions[1] - positions[0])
		#B-A = from a to b
		end_vector = Vector3(positions[positions.size()-1]- positions[positions.size()-2])
	
	#place buildings
	for index in range(numBuildings):
		placeBuilding(index)
	
	#in editor, we draw simple immediate mode lines instead
	if Engine.is_editor_hint():
		#debug drawing
		draw.draw_line(positions)
		draw.draw_line(left_positions)
		draw.draw_line(right_positions)
	
	pass

func initSection(start):
	#init positions
	temp_positions.push_back(Vector3(start.x-roadwidth, roadheight, start.z))
	temp_positions.push_back(start)
	temp_positions.push_back(Vector3(0, roadheight, start.z+sectionlength))
	temp_positions.push_back(Vector3(start.x-roadwidth, roadheight, start.z+sectionlength))
	temp_positions.push_back(Vector3(start.x+roadwidth, roadheight, start.z))
	temp_positions.push_back(Vector3(start.x+roadwidth, roadheight, start.z+sectionlength))
	# navmesh (#6-9)
	temp_positions.push_back(Vector3(start.x-roadwidth+margin, roadheight, start.z))
	temp_positions.push_back(Vector3(start.x-roadwidth+margin, roadheight, start.z+sectionlength))
	temp_positions.push_back(Vector3(start.x+roadwidth-margin, roadheight, start.z))
	temp_positions.push_back(Vector3(start.x+roadwidth-margin, roadheight, start.z+sectionlength))

func get_global_positions():
	global_positions = []
	global_positions.push_back(get_global_transform().xform(positions[0]))
	global_positions.push_back(get_global_transform().xform(mid_point))
	global_positions.push_back(get_global_transform().xform(positions[positions.size()-2]))
	global_positions.push_back(get_global_transform().xform(positions[positions.size()-1]))
		
	return global_positions


func draw_debug_point(loc, color):
	addTestColor(m, color, null, loc.x, 0.01, loc.z, 0.05,0.05,0.05)

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
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)

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
	
#props
func setupBuilding(index):
	var build = building.instance()
	#build.set_scale(Vector3(2, 2, 2))
	build.set_name("Skyscraper"+String(index))
	add_child(build)
	
	return build

func placeBuilding(index):
	var build = setupBuilding(index)
	
	#left side of the road
	var loc = Vector3(roadwidth+buildDistance, 0, index)
	if (index > 0):
		loc = Vector3(roadwidth+buildDistance, 0, index*10)
	else:
		loc = Vector3(roadwidth+buildDistance, 0, index)
	
	build.set_translation(loc)
	
	build = setupBuilding(index)
	#right side of the road
	loc = Vector3(-(roadwidth+buildDistance), 0, index)
	if (index > 0):
		loc = Vector3(-(roadwidth+buildDistance), 0, index*10)
	else:
		loc = Vector3(-(roadwidth+buildDistance), 0, index)
	
	build.set_translation(loc)
	
# navmesh
func setupNavi(navigation_node):
	#nav mesh
	nav_vertices = get_navi_vertices()
	navMesh(navigation_node, nav_vertices, true)
	nav_vertices_alt = get_navi_vertices_alt()
	navMesh(navigation_node, nav_vertices_alt, false)

func get_navi_vertices():
	var nav_vertices = PoolVector3Array()
	
	var pos_size = positions.size()-1
	nav_vertices.push_back(right_nav_positions[0])
	nav_vertices.push_back(positions[0])
	nav_vertices.push_back(positions[pos_size])
	nav_vertices.push_back(right_nav_positions[pos_size])
	
	return nav_vertices

func get_navi_vertices_alt():
	var nav_vertices = PoolVector3Array()
	
	var pos_size = positions.size()-1
	nav_vertices.push_back(positions[0])
	nav_vertices.push_back(left_nav_positions[0])
	nav_vertices.push_back(left_nav_positions[pos_size])
	nav_vertices.push_back(positions[pos_size])
	
	return nav_vertices

func navMesh(navigation_node, nav_vertices, left):
	
	var nav_mesh = NavigationMesh.new()
	
	nav_mesh.set_vertices(nav_vertices)
	
	var indices = []
	indices.push_back(0)
	indices.push_back(1)
	indices.push_back(2)
	indices.push_back(3)
	
	nav_mesh.add_polygon(indices)
	
	# create the actual navmesh and enable it
	var nav_mesh_inst = NavigationMeshInstance.new()	
	nav_mesh_inst.set_navigation_mesh(nav_mesh)
	nav_mesh_inst.set_enabled(true)
	
	# assign lane
	if (left):
		nav_mesh_inst.add_to_group("left_lane")
		nav_mesh_inst.set_name("nav_mesh_left_lane")
	else:
		nav_mesh_inst.add_to_group("right_lane")
		nav_mesh_inst.set_name("nav_mesh_right_lane")
		
	#navigation_node.call_deferred("add_child", nav_mesh_inst)
	navigation_node.add_child(nav_mesh_inst)
	
	# set global vertices
	global_vertices = PoolVector3Array()
	for index in range (nav_vertices.size()):
		global_vertices.push_back(get_global_transform().xform(nav_vertices[index]))


func updateGlobalVerts():
	print("Updating global verts ")
	global_vertices = PoolVector3Array()
	for index in range (nav_vertices.size()):
		# from local to global space
		var gl = get_global_transform().xform(nav_vertices[index])
		# from global to local relative to our parent (which is what is rotated/moved)
		var par_loc = get_parent().get_global_transform().xform_inv(gl)
		# from parent's local to global again
		var res = get_parent().get_global_transform().xform(par_loc)
		global_vertices.push_back(res) 
		
	# do the same for nav_vertices_alt
	global_vertices_alt = PoolVector3Array()
	for index in range (nav_vertices_alt.size()):
		#print("Writing alt vert to global")
		# from local to global space
		var gl = get_global_transform().xform(nav_vertices_alt[index])
		#print("Gl : " + str(gl))
		# from global to local relative to our parent (which is what is rotated/moved)
		var par_loc = get_parent().get_global_transform().xform_inv(gl)
		#print("Relative to parent " + str(par_loc))
		# from parent's local to global again
		var res = get_parent().get_global_transform().xform(par_loc)
		#print("Global again " + str(res))
		global_vertices_alt.push_back(res)


func move_key_navi_vertices(index1, pos1, index2, pos2):
	nav_vertices.set(index1, pos1)
	#print("Setting vertex " + String(index1) + " to " + String(pos1))
	nav_vertices.set(index2, pos2)
	#print("Setting vertex " + String(index2) + " to " + String(pos2))
	#print("New straight vertices " + String(nav_vertices[index1]) + " & " + String(nav_vertices[index2]))

func global_to_local_vert(pos):
	return get_global_transform().xform_inv(pos)
	
func send_positions(map):
	if positions.size() < 1:
		return
	print(get_name() + " sending position to map")
	global_positions = get_global_positions()
	map.add_positions(global_positions)
	
func lite_up():
	#print("Lit up road")
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_feature(SpatialMaterial.FEATURE_EMISSION, true)
	material.set_emission(Color(0,0,1))
	
func reset_lite():
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_feature(SpatialMaterial.FEATURE_EMISSION, false)
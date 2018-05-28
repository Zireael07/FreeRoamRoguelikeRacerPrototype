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
export(float) var road_slope = 0.0

var support_positions = PoolVector3Array()

#for matching
var start_point
export(Vector3) var relative_end

#navigation mesh
var nav_vertices
var global_vertices
var nav_vertices_alt
var global_vertices_alt
# margin
#var margin = 1
#var left_nav_positions = PoolVector3Array()
#var right_nav_positions = PoolVector3Array()

#for minimap
var mid_point
var global_positions = PoolVector3Array()

#for rotations
var end_vector
var start_vector
var start_ref
var end_ref

export(bool) var trees

#props
var building
var buildDistance = 10
#var numBuildings = 6
var buildingSpacing = 15
var building_tex1
var building_tex2
var sign_tex1
var sign_tex2
var sign_tex3
var win_mat
var win_mat2
var cables
var cherry_tree
var treeSpacing = 10

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	#add_to_group("roads")
	
	draw = get_node("draw")
	
	#props
	#building = preload("res://objects/skyscraper.tscn")
	#building = preload("res://objects/skyscraper-cube.tscn")
	building = preload("res://objects/procedural_building.tscn")
	building_tex1 = preload("res://assets/cement.tres")
	building_tex2 = preload("res://assets/brick_wall.tres")
	# more props
	sign_tex1 = preload("res://assets/neon_sign1.tres")
	sign_tex2 = preload("res://assets/neon_sign2.tres")
	sign_tex3 = preload("res://assets/neon_sign3.tres")
	# props
	win_mat = preload("res://assets/windows_material.tres")
	win_mat2 = preload("res://assets/windows_material2.tres")
	cables = preload("res://objects/china_cable.tscn")
	cherry_tree = preload("res://objects/cherry_tree.tscn")
	
	
	positions.resize(0) # = []
	left_positions.resize(0) # = []
	right_positions.resize(0) #= []
	
	#print("Positions: " + str(positions.size()))
	
	var quads = []
	var support_quads = []
	
	#overdraw fix
	if (get_parent().get_name().find("Spatial") != -1):
		# find out slope
		var slope_diff = road_slope/length
		#print("Slope diff" + str(slope_diff))
		
		#if slope_diff > 0:
			
		
		for index in range(length):
			#print("Index " + str(index))
			#clear the array
			temp_positions.resize(0)
			support_positions.resize(0)
			
			
			var start = Vector3(0,roadheight+(index*slope_diff),index*sectionlength)
			initSection(start, slope_diff)
	
			if slope_diff > 0:
				makeSupport(start, slope_diff)
				#support_quads.append(getQuadsSimple(support_positions))
	
			#mesh
			var num = temp_positions.size()
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
			# navmesh margin
			#left_nav_positions.push_back(temp_positions[6])
			#left_nav_positions.push_back(temp_positions[7])
			#right_nav_positions.push_back(temp_positions[8])
			#right_nav_positions.push_back(temp_positions[9])
			
			
			
		
		if Engine.is_editor_hint() or not Engine.is_editor_hint():
			#setupNavi(self)
			optimizedmeshCreate(quads, material)
			
			if support_positions.size() > 0:
				#optimizedmeshCreate(support_quads, building_tex1)
				var array = support_positions
				var surface = SurfaceTool.new()
				surface.begin(Mesh.PRIMITIVE_TRIANGLES)

				#Create a node building that will hold the mesh
				var node = MeshInstance.new()
				node.set_name("support")
				add_child(node)

				# cement is one sided for now
				addQuad(array[0], array[1], array[2], array[3], building_tex1, surface, false)
				addQuad(array[3], array[2], array[1], array[0], building_tex1, surface, false)
				
				# other side
				addQuad(array[4], array[5], array[6], array[7], building_tex1, surface, false)
				addQuad(array[7], array[6], array[5], array[4], building_tex1, surface, false)
				

				#Set the created mesh to the node
				node.set_mesh(surface.commit())	
			
		if not Engine.is_editor_hint():
			# disable the emissiveness
			reset_lite()
				
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
		
		start_ref = positions[0]+start_vector
		end_ref = positions[positions.size()-1]+end_vector
	
	#place buildings and lanterns
	if not trees:
		var numBuildings = int((sectionlength*length)/buildingSpacing)
		for index in range(numBuildings+1):
			placeBuilding(index)
			placeCable(index)
	else:
		var numTrees = int((sectionlength*length)/treeSpacing)
		for index in range(numTrees+1):
			placeTree(index)
	
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
	
	# kill debug draw in game
	else:
		draw.queue_free()
	
	#pass

func initSection(start, slope):
	var start_height = start.y
	var end_height = start.y + slope
	if slope > 0:
		print("Start height " + str(start_height) + " end height" + str(end_height))
	
	#init positions
	temp_positions.push_back(Vector3(start.x-roadwidth, start_height, start.z))
	temp_positions.push_back(start)
	temp_positions.push_back(Vector3(0, end_height, start.z+sectionlength))
	temp_positions.push_back(Vector3(start.x-roadwidth, end_height, start.z+sectionlength))
	temp_positions.push_back(Vector3(start.x+roadwidth, start_height, start.z))
	temp_positions.push_back(Vector3(start.x+roadwidth, end_height, start.z+sectionlength))
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


func draw_debug_point(loc, color):
	addTestColor(m, color, null, loc.x, 0.01, loc.z, 0.05,0.05,0.05)

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
	
#props
func setupBuilding(index):
	# seed the rng
	randomize()
	
	var ran = randf()
	
	var build = building.instance()
	
	if ran < 0.2:
		var mat = building_tex2
		build.material = mat
	else:
		var mat = building_tex1
		build.material = mat
	
	# storeys
	# number between 0-10
	var rani = randi() % 11
	build.storeys = 16 + rani
	
	# windows color
	var ran_color_r = randf()
	var ran_color_g = randf()
	var ran_color_b = randf()
	
	if ran < 0.5:
		var win_color = win_mat
		build.windows_mat = win_color
	else:
		var win_color = win_mat2
		build.windows_mat = win_color
	
	#build.windows_mat.
	
	#build.windows_mat.set_albedo(Color(ran_color_r, ran_color_g, ran_color_b))
	
		
	# sign material
	var rand = randf()
	
	
	if rand < 0.33:
		var sign_mat = sign_tex1
		build.get_node("MeshInstance").set_surface_material(0, sign_mat)
	elif rand < 0.66:
		var sign_mat = sign_tex2
		build.get_node("MeshInstance").set_surface_material(0, sign_mat)
	else:
		var sign_mat = sign_tex3
		build.get_node("MeshInstance").set_surface_material(0, sign_mat)
	
	# vary sign placement height
	var rand_i = randi() % 5
	
	build.get_node("MeshInstance").translate(Vector3(0, rand_i, 0))
	
	
	#build.set_scale(Vector3(2, 2, 2))
	build.set_name("Skyscraper"+String(index))
	add_child(build)
	
	return build

func placeBuilding(index):
	var build = setupBuilding(index)
	
	#left side of the road
	var loc = Vector3(roadwidth+buildDistance, 0, index)
	if (index > 0):
		loc = Vector3(roadwidth+buildDistance, 0, index*15)
	else:
		loc = Vector3(roadwidth+buildDistance, 0, index)
	
	build.set_translation(loc)
	build.set_rotation_degrees(Vector3(0, 180, 0))
	
	build = setupBuilding(index)
	#right side of the road
	loc = Vector3(-(roadwidth+buildDistance), 0, index)
	if (index > 0):
		loc = Vector3(-(roadwidth+buildDistance), 0, index*15)
	else:
		loc = Vector3(-(roadwidth+buildDistance), 0, index)
	
	build.set_translation(loc)
	
func placeCable(index):
	if (index % 2 > 0):
		var cable = cables.instance()
		cable.set_name("Cable"+String(index))
		add_child(cable)
	
		var loc = Vector3(0,3,index*15)
		cable.set_translation(loc)

func placeTree(index):
	var tree = cherry_tree.instance()
	tree.set_name("Tree"+String(index))
	add_child(tree)

	#left side of the road
	var loc = Vector3(roadwidth+(buildDistance/2), 0, index)
	if (index > 0):
		loc = Vector3(roadwidth+(buildDistance/2), 0, index*10)
	else:
		loc = Vector3(roadwidth+(buildDistance/2), 0, index)
	
	tree.set_translation(loc)
	
	tree = cherry_tree.instance()
	tree.set_name("Tree"+String(index))
	add_child(tree)
	
	#right side of the road
	loc = Vector3(-(roadwidth+(buildDistance/2)), 0, index)
	if (index > 0):
		loc = Vector3(-(roadwidth+(buildDistance/2)), 0, index*10)
	else:
		loc = Vector3(-(roadwidth+(buildDistance/2)), 0, index)
	
	tree.set_translation(loc)
	
	
# navmesh
func setupNavi(navigation_node):
	#nav mesh
	nav_vertices = get_navi_vertices()
	navMesh(navigation_node, nav_vertices, true)
	nav_vertices_alt = get_navi_vertices_alt()
	navMesh(navigation_node, nav_vertices_alt, false)

#func get_navi_vertices():
#	var nav_vertices = PoolVector3Array()
#
#	var pos_size = positions.size()-1
#	nav_vertices.push_back(right_nav_positions[0])
#	nav_vertices.push_back(positions[0])
#	nav_vertices.push_back(positions[pos_size])
#	nav_vertices.push_back(right_nav_positions[pos_size])
#
#	return nav_vertices
#
#func get_navi_vertices_alt():
#	var nav_vertices = PoolVector3Array()
#
#	var pos_size = positions.size()-1
#	nav_vertices.push_back(positions[0])
#	nav_vertices.push_back(left_nav_positions[0])
#	nav_vertices.push_back(left_nav_positions[pos_size])
#	nav_vertices.push_back(positions[pos_size])
#
#	return nav_vertices

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
	if nav_vertices == null or nav_vertices.size() < 1:
		return
	
	print("Updating global verts")
	
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
	#print(get_name() + " sending position to map")
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
	
func rain_shine():
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_roughness(0.2)
	
func no_rain():
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_roughness(1.0)
@tool

extends "../scripts/meshes/mesh_gen.gd"

# class member variables go here, for example:
@export var material : Material = preload("res://assets/road_material.tres")
var temp_positions = PackedVector3Array()

#editor drawing
var positions = [] # PackedVector3Array() PV3 does not have has() ...
var left_positions = [] #PackedVector3Array()
var right_positions = [] #PackedVector3Array()
var draw = null


var length = 5.0 # how many sections?
var roadwidth = 3
var sectionlength = 2
var roadheight = 0.01
@export var road_slope: float = 0.0

#sidewalks
@export var sidewalks: bool = false
var points_inner_side = PackedVector3Array()
var points_outer_side = PackedVector3Array()
# mesh
var sidewalk_left = PackedVector3Array()
var sidewalk_right = PackedVector3Array()

@export var guardrails: bool = false
# debugging
var points_inner_rail = PackedVector3Array()
var points_outer_rail = PackedVector3Array()
# actual mesh
var rail_positions_left = PackedVector3Array()
var rail_positions_right = PackedVector3Array()

var support_positions = PackedVector3Array()

#for matching
var start_point = Vector3()
@export var relative_end: Vector3 = Vector3(0,0,100)

#for minimap
var mid_point = Vector3()
var global_positions = PackedVector3Array()

#for rotations
var end_vector = Vector3()
var start_vector = Vector3()
var start_ref = Vector3()
var end_ref = Vector3()

@export var trees: bool = false
@export var bamboo: bool = false
@export var tunnel: bool = false

## materials
var railing_tex = null
var cement_tex = null

var tunnel_obj = null

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	#add_to_group("roads")
	
	draw = get_node(^"draw")
	
	railing_tex = preload("res://assets/railing_material.tres")
	cement_tex = preload("res://assets/cement.tres")	
	tunnel_obj = preload("res://objects/tunnel_mesh.tscn")
	
	generateRoad()
	
	# test
	#global_to_road_relative(get_global_transform() * Vector3(10, 0, 44))

func generateRoad():
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
	#if (get_parent().get_name().find("Node3D") != -1):
	makeRoad()
	
	#place props
	get_node(^"Node3D").place_props(trees, bamboo, sectionlength*length)

func makeRoad():
	var quads = []
	var cap_quads = []
	#var support_quads = []
	var rail_quads = []
	var side_quads = []
	
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
		sidewalk_left.resize(0)
		sidewalk_right.resize(0)
		
		
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

		# avoid inserting duplicates
		if not positions.has(temp_positions[1]):
			positions.push_back(temp_positions[1])
		if not positions.has(temp_positions[2]):
			positions.push_back(temp_positions[2])
		
		if not left_positions.has(temp_positions[0]):	
			left_positions.push_back(temp_positions[0])
		if not left_positions.has(temp_positions[3]):
			left_positions.push_back(temp_positions[3])
		
		if not right_positions.has(temp_positions[4]):
			right_positions.push_back(temp_positions[4])
		if not right_positions.has(temp_positions[5]):
			right_positions.push_back(temp_positions[5])
		
		if sidewalks:
			#print("We have sidewalks or guardrails, need more positions")
			points_inner_side.push_back(temp_positions[6])
			points_inner_side.push_back(temp_positions[7])
			points_outer_side.push_back(temp_positions[8])
			points_outer_side.push_back(temp_positions[9])
			
			sidewalk_left.push_back(temp_positions[0])
			sidewalk_left.push_back(temp_positions[6])
			sidewalk_left.push_back(temp_positions[7])
			sidewalk_left.push_back(temp_positions[3])
			
			sidewalk_right.push_back(temp_positions[4])
			sidewalk_right.push_back(temp_positions[8])
			sidewalk_right.push_back(temp_positions[9])
			sidewalk_right.push_back(temp_positions[5])
			
			side_quads.append(getQuadsSimple(sidewalk_left))
			side_quads.append(getQuadsSimple(sidewalk_right))
			
		
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
		# end loop	
	
	if Engine.is_editor_hint() or not Engine.is_editor_hint():
		#setupNavi(self)

		# road cap		
		if length-int(length) > 0:
			roadCap((length-int(length)), cap_quads, slope_diff)
		
		optimizedmeshCreate(quads, cap_quads, material)
		
		# bonus stuffs
		if sidewalks:
			var surface = SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			#Create a node that will hold the mesh
			var node = MeshInstance3D.new()
			node.set_name("sidewalk")
			add_child(node)
			
			for qu in side_quads:
				addQuad(qu[0], qu[1], qu[2], qu[3], cement_tex, surface, false)
				addQuad(qu[3], qu[2], qu[1], qu[0], cement_tex, surface, false)

			surface.generate_normals()
			surface.index()
		
			#Set the created mesh to the node
			node.set_mesh(surface.commit())
			
			#Turn off shadows
			node.set_cast_shadows_setting(0)
			
			# yay GD 3
			#node.create_convex_collision()
			

		
		if support_positions.size() > 0:
			#optimizedmeshCreate(support_quads, building_tex1)
			var array = support_positions
			var surface = SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)

			#Create a node that will hold the mesh
			var node = MeshInstance3D.new()
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
			var node = MeshInstance3D.new()
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
			#node.create_trimesh_collision()
				
		if tunnel:
			var tun = tunnel_obj.instantiate()
			var sc = round(floor(relative_end.z/50))
			tun.set_scale(Vector3(1.2, 1.0, sc))
			tun.set_name("tunnel")
			add_child(tun)
		
		
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
#			draw.draw_line(positions)
#			draw.draw_line(left_positions)
#			draw.draw_line(right_positions)
#			draw.draw_line(debug_start_axis)
#			draw.draw_line(debug_end_axis)
#			if points_inner_side.size() > 0:
#				draw.draw_line(points_inner_side)
#				draw.draw_line(points_outer_side)
#
#			if points_inner_rail.size() > 0:
#				draw.draw_line(points_inner_rail)
#				draw.draw_line(points_outer_rail)
	
	
	# kill debug draw in game
	else:
		draw.queue_free()

	# workaround for https://github.com/godotengine/godot/issues/36729
	# if we're on the ground and not sloped, we don't need a collision shape
	if global_transform.origin.y < 1 and road_slope < 0.1:
		var shape = BoxShape3D.new()
		shape.set_size(Vector3(6,1,mid_point.z*2))
		get_node(^"Area3D/CollisionShape3D").set_position(Vector3(0,0,mid_point.z))
		get_node(^"Area3D/CollisionShape3D").set_shape(shape)
	# otherwise make a simple collision shape
	else:
		var shape = BoxShape3D.new()
		shape.set_size(Vector3(6,3, (mid_point.z*2)+0.2)) #fudge necessary for bike not to fall through a crack
		var body = StaticBody3D.new()
		body.set_collision_layer(2) # AI raycasts ignore layer 2
		add_child(body)
		var coll = CollisionShape3D.new()
		body.add_child(coll)
		coll.set_shape(shape)
		# if sloped, just rotate the box shape
		if road_slope > 0.1:
			# Godot's atan is y,x
			var rot = -atan2(end_ref.y-mid_point.y, end_ref.z-mid_point.z)
			coll.set_rotation(Vector3(rot, 0,0))
			coll.set_position(Vector3(0, -0.4, mid_point.z))
			
			# prevent falling off (especially AI)
			coll = CollisionShape3D.new()
			shape = BoxShape3D.new()
			shape.set_size(Vector3(2,3, mid_point.z-1))
			body.add_child(coll)
			coll.set_shape(shape)
			coll.set_rotation(Vector3(rot, 0,0))
			coll.set_position(Vector3(6,0,mid_point.z))
			# other side
			coll = CollisionShape3D.new()
			shape = BoxShape3D.new()
			shape.set_size(Vector3(2,3, mid_point.z-1))
			body.add_child(coll)
			coll.set_shape(shape)
			coll.set_rotation(Vector3(rot, 0,0))
			coll.set_position(Vector3(-6,0,mid_point.z))
			
		else:
			coll.set_position(Vector3(0,-2.9, mid_point.z))
	

	
#	if relative_end.z > 250:
#		var shape = BoxShape3D.new()
#		shape.set_extents(Vector3(6,0.05,125))
#		get_node(^"StaticBody3D/CollisionShape3D").set_translation(Vector3(0,0,125))
#		get_node(^"StaticBody3D/CollisionShape3D").set_shape(shape)
#
#
#		#var sh = CollisionShape3D.new()
#		#get_node(^"StaticBody3D").add_child(sh)
#		#shape = BoxShape3D.new()
#		#shape.set_extents(Vector3(6,0.02, (relative_end.z-250)/2))
#		#get_node(^"StaticBody3D").get_child(1).set_translation(Vector3(0,0,relative_end.z-250))
#		#get_node(^"StaticBody3D").get_child(1).set_shape(shape)
#
#	else:
#		var shape = BoxShape3D.new()
#		shape.set_extents(Vector3(6,0.05,mid_point.z))
#		get_node(^"StaticBody3D/CollisionShape3D").set_translation(Vector3(0,0,mid_point.z))
#		get_node(^"StaticBody3D/CollisionShape3D").set_shape(shape)


func roadCap(diff, cap_quads, slope_diff):
	temp_positions.resize(0)

	var start = Vector3(0,roadheight+(int(length)*slope_diff),(int(length))*sectionlength)
	#print("Cap start: " + str(start))
	initSection(start, slope_diff, diff*2)
	#print(str(temp_positions))
	
	# calculate UVs
	var uv_r = length-int(length)/1
	#var uv_r = 1
	var uvs_cap = [Vector2(0,0), Vector2(0,1), Vector2(uv_r,1), Vector2(uv_r,0), Vector2(1-uv_r, 1), Vector2(1-uv_r, 0)]
	
	var array = temp_positions
	var quad_one = [array[0], array[1], array[2], array[3], uvs_cap[0], uvs_cap[1], uvs_cap[2], uvs_cap[3]]
	var quad_two = [array[1], array[4], array[5], array[2], uvs_cap[2], uvs_cap[3], uvs_cap[0], uvs_cap[1]]
	
	cap_quads.append(quad_one)
	cap_quads.append(quad_two)

func initSection(start, slope, length=sectionlength):
	var start_height = start.y
	var end_height = start.y + slope
#	if slope > 0:
#		print("Start height " + str(start_height) + " end height" + str(end_height))
	
	#init positions
	temp_positions.push_back(Vector3(start.x-roadwidth, start_height, start.z)) #0
	temp_positions.push_back(start) #1
	temp_positions.push_back(Vector3(0, end_height, start.z+length)) #2
	temp_positions.push_back(Vector3(start.x-roadwidth, end_height, start.z+length)) #3
	temp_positions.push_back(Vector3(start.x+roadwidth, start_height, start.z)) #4
	temp_positions.push_back(Vector3(start.x+roadwidth, end_height, start.z+length)) #5
	
	# sides
	if sidewalks:
		var width_with_side = roadwidth*1.5
		
		temp_positions.push_back(Vector3(start.x-width_with_side, start_height+0.05, start.z)) #6
		temp_positions.push_back(Vector3(start.x-width_with_side, end_height+0.05, start.z+length))
		temp_positions.push_back(Vector3(start.x+width_with_side, start_height+0.05, start.z))
		temp_positions.push_back(Vector3(start.x+width_with_side, end_height+0.05, start.z+length)) #9
	
	if guardrails:
		temp_positions.push_back(Vector3(start.x-roadwidth, start_height + 1, start.z))
		temp_positions.push_back(Vector3(start.x-roadwidth, end_height + 1, start.z+length))
		temp_positions.push_back(Vector3(start.x+roadwidth, start_height + 1, start.z))
		temp_positions.push_back(Vector3(start.x+roadwidth, end_height + 1, start.z + length))
	

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
	global_positions.push_back(get_global_transform() * (positions[0]))
	global_positions.push_back(get_global_transform() * (mid_point))
	global_positions.push_back(get_global_transform() * (positions[positions.size()-2]))
	global_positions.push_back(get_global_transform() * (positions[positions.size()-1]))
		
	return global_positions

func getQuadsSimple(array):
	var quad_one = [array[0], array[1], array[2], array[3], false]
	
	return quad_one

func getQuads(array):
	var quad_one = [array[0], array[1], array[2], array[3], false]
	var quad_two = [array[1], array[4], array[5], array[2], true]
	
	return [quad_one, quad_two]

func optimizedmeshCreate(quads, cap_quads, material):
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance3D.new()
	node.set_name("plane")
	add_child(node)
	
	for qu in quads:
		addQuad(qu[0], qu[1], qu[2], qu[3], material, surface, qu[4])
	
	
	for qu in cap_quads:
		addQuadCustUV(qu[0], qu[1], qu[2], qu[3], qu[4], qu[5], qu[6], qu[7], material, surface)
	
	surface.generate_normals()
	
	surface.index()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)
	
	# yay GD 3
	#node.create_convex_collision()


func meshCreate(array, material):
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance3D.new()
	node.set_name("plane")
	add_child(node)
	
	addQuad(array[0], array[1], array[2], array[3], material, surface, false)
	addQuad(array[1], array[4], array[5], array[2], material, surface, true)
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)

func global_to_local_vert(pos):
	return pos * get_global_transform()
	
func send_positions(map):
	if positions.size() < 1:
		return
	#print(get_name() + " sending position to map")
	global_positions = get_global_positions()
	map.add_positions(global_positions)

# ---------------------------------------------------------------	
func lite_up():
	#print("Lit up road")
	var material = get_node(^"plane").get_mesh().surface_get_material(0)
	material.set_shader_uniform("emission_energy", 3)
	material.set_shader_uniform("emission", Color(0,0,1))
	#material.set_feature(StandardMaterial3D.FEATURE_EMISSION, true)
	#material.set_emission(Color(0,0,1))
	
func reset_lite():
	var material = get_node(^"plane").get_mesh().surface_get_material(0)
	material.set_shader_uniform("emission_energy", 0)
	#material.set_feature(StandardMaterial3D.FEATURE_EMISSION, false)
	
func rain_shine(rain_amount):
	var material = get_node(^"plane").get_mesh().surface_get_material(0)
	material.set_roughness(0.2)
	material.set_metallic(0.85)
	material.set_shader_uniform("puddle_size", rain_amount)
	
func no_rain():
	var material = get_node(^"plane").get_mesh().surface_get_material(0)
	material.set_shader_uniform("roughness", 1.0)
	material.set_shader_uniform("metallic", 0.0)
	material.set_shader_uniform("puddle_size", 0.0)
	#material.set_roughness(1.0)
	#material.set_metallic(0.0)

func debug_tunnel():
	# works but makes buildings transparent, too
	var tun = get_node(^"tunnel").get_mesh().surface_get_material(0)
	tun.set_transparency(1)
	#tun.set_feature(StandardMaterial3D.FEATURE_TRANSPARENT, true)
	#var tun = get_node(^"tunnel")
	#tun.hide()
	
func show_tunnel():
	var tun = get_node(^"tunnel").get_mesh().surface_get_material(0)
	tun.set_transparency(0)
	#tun.set_feature(StandardMaterial3D.FEATURE_TRANSPARENT, false)
	#var tun = get_node(^"tunnel")
	#tun.show()


func _on_Area_body_entered(body):
	if body is CharacterBody3D and 'hit' in body:
		body.hit = self
		print("Entered area: ", get_parent().get_parent().get_name())
	pass # Replace with function body.


func _on_Area_body_exited(body):
	if body is CharacterBody3D and 'hit' in body:
		body.hit = null
		print("Exited area: ", get_parent().get_parent().get_name(), " ,", body.hit)
	pass # Replace with function body.

# https://web.archive.org/web/20160310163127/http://blogs.msdn.com/b/shawnhar/archive/2009/12/30/motogp-ai-coordinate-systems.aspx
func global_to_road_relative(gloc):
	var rel_loc = to_local(gloc)
	return local_to_road_relative(rel_loc)

func local_to_road_relative(loc):
	# road relative position is how far along the track (x) and how far to the side (y)
	# this operates on relative positions so we don't need anything fancy
	# our road is always aligned along local +Z
	# let's make our "along" between 0.0 (start) and 1.0 (end)
	var along = clamp(loc.z/relative_end.z, 0.0, 1.0)
	# TODO: this could be made absolute by multiplying by length or just using the loc.z directly
	#print("Along: ", along)
	
	# how far to the side?
	# all we need is loc.x
	var side = abs(loc.x)
	
#	# find a point on the center line at along
#	# a bit simplified but should work
#	# can't lerp ints :(
#	#var id = lerp(0, points_center.size()-1, along)
#	var id = Tween.interpolate_value(0, points_center.size()-1, along, 1.0, Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
#	var cntr = Vector3(points_center[id].x, road_height, points_center[id].y)
#	print("Center point for along: #", int(id), ", ", points_center[int(id)])
#
#	var side = cntr.distance_to(loc)
	
	print("Road relative pos for ", loc, " : ", Vector2(along, side))
	return Vector2(along, side)
	

@tool
extends "../scripts/meshes/mesh_gen.gd"

@export    var material    = preload("res://assets/road_material.tres")
var m = Material.new()

var road_height = 0.05
var road_width = 3

# points
var point_one = Vector3(0,0,10)
var point_two = Vector3(10,0,0)
var point_three = Vector3(0,0,-10)

var open_exits = [point_one, point_two, point_three]
var used_exits = {}

var pointone_left #= Vector3(2,0,4)
var pointone_right #= Vector3(-2,0,4)

var middle_left #= Vector3(2,0,0)
var middle_right #= Vector3(-2,0,0)

var middle_center
var middle_bottom
var middle_top

var pointtwo_right #= Vector3(6,0,0)
var pointtwo_left #= Vector3(6,0,-4)

var middle_bottom_left #= Vector3(2,0,-4)

var point_three_left #= Vector3(2,0,-8)
var point_three_right# = Vector3(-2,0,-8)

var middle_bottom_right #= Vector3(-2,0,-4)

var array = []
var positions_left = []
var positions_right = []

var draw
var flip_mat = preload("res://assets/car/car_blue.tres")

var cars = {}

func _ready():
	#draw = get_node(^"draw")
	
	array = []
	positions_left = []
	positions_right = []
	
	# calculate the points
	pointone_left = Vector3(point_one.x + road_width, point_one.y, point_one.z)
	#pointone_mid = Vector3(point_one.x, point_one.y, point_one.z)
	pointone_right = Vector3(point_one.x - road_width, point_one.y, point_one.z)
	
	pointtwo_right = Vector3(point_two.x, point_two.y, point_two.z + road_width)
	#pointtwo_mid = Vector3(point_two.x, point_two.y, point_two.z)
	pointtwo_left = Vector3(point_two.x, point_two.y, point_two.z - road_width)
	
	point_three_left = Vector3(point_three.x + road_width, point_three.y, point_three.z)
	#point_three_mid = Vector3(point_three.x, point_three.y, point_three.z)
	point_three_right = Vector3(point_three.x - road_width, point_three.y, point_three.z)
	
	# calculate the middle points
	middle_left = Vector3(point_one.x + road_width,0, point_two.z + road_width)
	middle_right = Vector3(point_one.x - road_width,0,point_two.z + road_width)
	
	middle_bottom_left = Vector3(point_one.x+road_width, 0, point_two.z - road_width) 
	middle_bottom_right = Vector3(point_one.x-road_width, 0, point_two.z - road_width)
	
	middle_center = Vector3(point_one.x, 0, point_two.z + road_width)
	middle_bottom = Vector3(point_one.x, 0, point_two.z - road_width)
	
	middle_top = Vector3(point_one.x+road_width, 0, point_two.z)
	
	
	array.push_back(pointone_left) #0
	array.push_back(point_one)
	array.push_back(middle_center)
	array.push_back(middle_left) #3
	array.push_back(pointone_right) #1
	array.push_back(middle_right) #2
	
	#second part
	array.push_back(pointtwo_left) #6
	array.push_back(point_two)
	array.push_back(pointtwo_right)
	array.push_back(middle_bottom_left)
	array.push_back(middle_top)
	
	# third part (other end of main road)
	array.push_back(point_three_left) #11
	array.push_back(point_three)
	array.push_back(middle_bottom)
	array.push_back(point_three_right)
	array.push_back(middle_bottom_right)
	
	
	meshCreate(material, array)
	
#	debug_cube(middle_top)
	
#	positions_left.push_back(pointone_left)
#	positions_left.push_back(middle_left)
#	positions_left.push_back(pointtwo_right)
#	
#	positions_right.push_back(pointtwo_left)
#	positions_right.push_back(middle_bottom_left)
#	positions_right.push_back(point_three_left)
	
	
	
	if Engine.is_editor_hint():
		#debug drawing
		if draw != null:
			draw.draw_line(positions_left, 3, false)
			draw.draw_line(positions_right,3, false)
	

func meshCreate(material, array):
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance3D.new()
	node.set_name("plane")
	add_child(node)
	
	# one end
	addQuad(array[0], array[1], array[2], array[3], material, surface, false)
	addQuad(array[1], array[4], array[5], array[2], material, surface, true)
	
	# other end
	addQuad(array[11], array[12], array[13], array[9], material, surface, false)
	addQuad(array[12], array[14], array[15], array[13], material, surface, true)
	
	
	# second road
	addQuad(array[6], array[7], array[10], array[9], material, surface, false)
	addQuad(array[7], array[8], array[3], array[10], material, surface, true)
	
	
	# center
	addQuad(array[3], array[5], array[15], array[9], material, surface, true)
	
	surface.generate_normals()
	surface.index()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)
	
	# yay GD 3
	node.create_convex_collision()
	
# debug
func debug_cube(loc, red=false):
	var mesh = BoxMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance3D.new()
	node.set_mesh(mesh)
	if red:
		node.get_mesh().surface_set_material(0, flip_mat)
	node.set_name("Debug")
	add_child(node)
	node.set_translation(loc)
	
func send_position(map):
	#pass
	map.add_intersection(get_global_transform() * (Vector3(0,0,0)))

func snap_pos_to_points(pos):
	if abs(pos.x) > abs(pos.z):
		if pos.x > 0:
			pos = point_two
		#if pos.x < 0 and 'point_four' in self:
		#	pos = point_four
	else:
		if pos.z > 0:
			pos = point_one
		if pos.z < 0:
			pos = point_three
			
	return pos

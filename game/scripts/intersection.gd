tool
extends "mesh_gen.gd"

export(SpatialMaterial)    var material    = preload("res://assets/road_material.tres")
var m = SpatialMaterial.new()

var road_height = 0.05
var road_width = 3

# points
var point_one = Vector3(0,0,10)
var point_two = Vector3(12,0,0)
var point_three = Vector3(0,0,-10)


var pointone_left #= Vector3(2,0,4)
var pointone_right #= Vector3(-2,0,4)

var middle_left #= Vector3(2,0,0)
var middle_right #= Vector3(-2,0,0)


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

func _ready():
	#draw = get_node("draw")
	
	array = []
	positions_left = []
	positions_right = []
	
	# calculate the points
	pointone_left = Vector3(point_one.x + road_width, point_one.y, point_one.z)
	pointone_right = Vector3(point_one.x - road_width, point_one.y, point_one.z)
	
	pointtwo_right = Vector3(point_two.x, point_two.y, point_two.z + road_width)
	pointtwo_left = Vector3(point_two.x, point_two.y, point_two.z - road_width)
	
	point_three_left = Vector3(point_three.x + road_width, point_three.y, point_three.z)
	point_three_right = Vector3(point_three.x - road_width, point_three.y, point_three.z)
	
	# calculate the middle points
	middle_left = Vector3(point_one.x + road_width,0, point_two.z + road_width)
	middle_right = Vector3(point_one.x - road_width,0,point_two.z + road_width)
	
	middle_bottom_left = Vector3(point_one.x+road_width, 0, point_two.z - road_width) 
	middle_bottom_right = Vector3(point_one.x-road_width, 0, point_two.z - road_width)
	
	
	array.push_back(pointone_left)
	array.push_back(pointone_right)
	array.push_back(middle_right)
	array.push_back(middle_left)
	#second part
	array.push_back(pointtwo_left)
	array.push_back(pointtwo_right)
	array.push_back(middle_bottom_left)
	# third part
	array.push_back(point_three_left)
	array.push_back(point_three_right)
	array.push_back(middle_bottom_right)
	
	meshCreate(material, array)
	
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
	var node = MeshInstance.new()
	node.set_name("plane")
	add_child(node)
	
	addQuad(array[0], array[1], array[2], array[3], material, surface, false)
	addQuad(array[4], array[5], array[3], array[6], material, surface, true)
	addQuad(array[8], array[7], array[6], array[9], material, surface, false)
	
	# center
	addQuad(array[3], array[2], array[9], array[6], material, surface, true)
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)
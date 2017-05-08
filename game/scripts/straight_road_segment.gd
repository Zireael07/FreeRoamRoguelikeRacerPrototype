tool

extends "mesh_gen.gd"

# class member variables go here, for example:
var m = FixedMaterial.new()
var color = Color(1,0,0)
export(FixedMaterial)    var material    = preload("res://assets/road_material.tres")
var positions = Vector3Array()

export(int) var length = 5
var roadwidth = 3
var sectionlength = 2
var roadheight = 0.01


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	#overdraw fix
	if (get_parent().get_name() == "Spatial"):
		for index in range(length):
			#clear the array
			positions.resize(0)
			var start = Vector3(0,roadheight,index*sectionlength)
			initSection(start)
	
			#draw
			var num = positions.size()
			for index in range(num):
				##draw_debug_point(positions[index], color)
			
				meshCreate(positions, material)
	
	pass

func initSection(start):
	#init positions
	positions.push_back(Vector3(start.x-roadwidth, roadheight, start.z))
	positions.push_back(start)
	positions.push_back(Vector3(0, roadheight, start.z+sectionlength))
	positions.push_back(Vector3(start.x-roadwidth, roadheight, start.z+sectionlength))
	positions.push_back(Vector3(start.x+roadwidth, roadheight, start.z))
	positions.push_back(Vector3(start.x+roadwidth, roadheight, start.z+sectionlength)) 

func draw_debug_point(loc, color):
	addTestColor(m, color, null, loc.x, 0.01, loc.z, 0.05,0.05,0.05)

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
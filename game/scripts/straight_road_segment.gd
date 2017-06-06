tool

extends "mesh_gen.gd"

# class member variables go here, for example:
var m = FixedMaterial.new()
var color = Color(1,0,0)
export(FixedMaterial)    var material    = preload("res://assets/road_material.tres")
var temp_positions = Vector3Array()

#editor drawing
var positions = Vector3Array()
var left_positions = Vector3Array()
var right_positions = Vector3Array()
var draw


export(int) var length = 5
var roadwidth = 3
var sectionlength = 2
var roadheight = 0.01

#for matching
var start_point
export(Vector3) var relative_end

#for minimap
var mid_point
var global_positions = Vector3Array()

#for rotations
var end_vector
var start_vector


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	draw = get_node("draw")
	
	#overdraw fix
	if (get_parent().get_name() == "Spatial"):
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
				if not get_tree().is_editor_hint():
					meshCreate(temp_positions, material)
				positions.push_back(temp_positions[1])
				positions.push_back(temp_positions[2])
				left_positions.push_back(temp_positions[0])
				left_positions.push_back(temp_positions[3])
				right_positions.push_back(temp_positions[4])
				right_positions.push_back(temp_positions[5])
				
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
	
	
	
	#in editor, we draw simple immediate mode lines instead
	if get_tree().is_editor_hint():
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

func get_global_positions():
	global_positions.push_back(get_global_transform().xform(positions[0]))
	global_positions.push_back(get_global_transform().xform(mid_point))
	global_positions.push_back(get_global_transform().xform(positions[positions.size()-2]))
	global_positions.push_back(get_global_transform().xform(positions[positions.size()-1]))
		
	return global_positions


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
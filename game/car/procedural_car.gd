tool
extends "res://scripts/mesh_gen.gd"

# class member variables go here, for example:
export var door_h = 0.55
export var window_h = 0.35
#export var hood_h = 0.65
export var rh = 0.35
export var door = 0.4
export var front = 0.8
export var rear = 0.7
export var roof_w = 0.5

export var well_h = 0.25
export var well_w = 0.4

export var width = 1.0

export(FixedMaterial) var material = FixedMaterial.new()

func _ready():
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("plane")
	add_child(node)
	
	#do the stuff
	createCar(surface, node)
	
func createCar(surface, node):
	# sides
	var halfwidth = float(width/2)

	createSide(surface, -halfwidth, false)
	createSide(surface, halfwidth, true)
	
	#make them visible no matter the side
	createSide(surface, -halfwidth, true)
	createSide(surface, halfwidth, false)
	
	createBody(surface, halfwidth)
	
	# roof
	var top_win_left = Vector3(-halfwidth,door_h+window_h, -door+(roof_w/2))
	var top_win_right = Vector3(halfwidth, door_h+window_h, -door+(roof_w/2))
	var top_win_rear_l = Vector3(-halfwidth,door_h+window_h, -door-(roof_w/2))
	var top_win_rear_r = Vector3(halfwidth, door_h+window_h, -door-(roof_w/2))
	
	#visible from the top
	addQuad(top_win_left, top_win_rear_l, top_win_rear_r, top_win_right, material, surface, false)
	addQuad(top_win_right, top_win_rear_r, top_win_rear_l, top_win_left, material, surface, false)
	
	# bottom
	var front_left = Vector3(-halfwidth,0,front)
	var front_right = Vector3(halfwidth,0,front)
	var rear_left = Vector3(-halfwidth,0,-door*2-rear)
	var rear_right = Vector3(halfwidth,0,-door*2-rear)
	
	var rear_wheel_z = -door*2-0.1-(well_w/2)
	var well_side_l_left = Vector3(-halfwidth, 0, rear_wheel_z+(well_w/2))
	var well_side_r_left = Vector3(-halfwidth, 0, rear_wheel_z-(well_w/2))
	var well_side_l_right = Vector3(halfwidth, 0, rear_wheel_z+(well_w/2))
	var well_side_r_right = Vector3(halfwidth, 0, rear_wheel_z-(well_w/2))
	
	var front_wheel_z = 0.1+(well_w/2)
	var front_side_l_left = Vector3(-halfwidth, 0, front_wheel_z-(well_w/2))
	var front_side_r_left = Vector3(-halfwidth, 0, front_wheel_z+(well_w/2))
	var front_side_l_right = Vector3(halfwidth, 0, front_wheel_z-(well_w/2))
	var front_side_r_right = Vector3(halfwidth, 0, front_wheel_z+(well_w/2))
	
	addQuad(front_right, front_side_r_right, front_side_r_left, front_left, material, surface, false)
	addQuad(front_side_l_right, well_side_l_right, well_side_l_left, front_side_l_left, material, surface, false)
	addQuad(well_side_r_right, rear_right, rear_left, well_side_r_left, material, surface, false)
	
	# visible from the top
	addQuad(front_left, front_side_r_left, front_side_r_right, front_right, material, surface, false)
	addQuad(front_side_l_left, well_side_l_left, well_side_l_right, front_side_l_right, material, surface, false)
	addQuad(well_side_r_left, rear_left, rear_right, well_side_r_right, material, surface, false)
	
	surface.generate_normals()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())
	
func createSide(surface, x_offset, flip):
	var one = Vector3(x_offset,0,0)
	var two = Vector3(x_offset,0,-door)
	var three = Vector3(x_offset,door_h,-door)
	var four = Vector3(x_offset,door_h,0)
	
	if flip:
		addQuad(four, three, two, one, material, surface, false)
	else:
		addQuad(one,two, three, four, material, surface, false)
	
	#second door
	var five = Vector3(x_offset,0, -door*2)
	var six = Vector3(x_offset,door_h,-door*2)
	
	if flip:
		addQuad(three, six, five, two, material, surface, false)
	else:
		addQuad(two, five, six, three, material, surface, false)
	
	# rear (with wheel wells)
	createRear(x_offset, flip, surface)
	
	# front
	createFront(x_offset, flip, surface)
	
	var r_edge_roof = -door-(roof_w/2)
	var l_edge_roof = -door+(roof_w/2)
	var top_m = Vector3(x_offset,door_h+window_h, -door)
	var top_r = Vector3(x_offset,door_h+window_h, r_edge_roof)
	var top_l = Vector3(x_offset,door_h+window_h, l_edge_roof)
	
	if flip:
		addQuad(top_l, top_r, six, four, material, surface, false)
	else:
		addQuad(four, six, top_r, top_l, material, surface, false)
		
func createRear(x_offset, flip, surface):
	var five = Vector3(x_offset,0, -door*2)
	var six = Vector3(x_offset,door_h,-door*2)
	var seven = Vector3(x_offset,0,-door*2-rear)
	var eight = Vector3(x_offset,rh,-door*2-rear)
	
	var wheel_z = -door*2-0.1-(well_w/2)
	var well_top = Vector3(x_offset, well_h, wheel_z)
	var well_side_l = Vector3(x_offset, 0, wheel_z+(well_w/2))
	var well_side_r = Vector3(x_offset, 0, wheel_z-(well_w/2))
	
	if flip:
		createWell(five, six, seven, eight, well_top, well_side_l, well_side_r, surface, true)
	else:
		createWell(five, six, seven, eight, well_top, well_side_l, well_side_r, surface, false)

func createFront(x_offset, flip, surface):
	var one = Vector3(x_offset,0,0)
	var four = Vector3(x_offset,door_h,0)
	var nine = Vector3(x_offset,0,front)
	var ten = Vector3(x_offset,rh,front)
	
	var wheel_z = 0.1+(well_w/2)
	var well_top = Vector3(x_offset, well_h, wheel_z)
	var well_side_l = Vector3(x_offset, 0, wheel_z-(well_w/2))
	var well_side_r = Vector3(x_offset, 0, wheel_z+(well_w/2))
	
	# hack to avoid weird ordering
	if flip:
		createWell(one, four, nine, ten, well_top, well_side_l, well_side_r, surface, false)
	else:
		createWell(one, four, nine, ten, well_top, well_side_l, well_side_r, surface, true)

func createWell(one, two, three, four, well_top, well_side_l, well_side_r, surface, flip):
	if flip:
		addQuad(well_side_r, well_top, four, three, material, surface, false)
		addQuad(one, two, well_top, well_side_l, material, surface, false)
		addTri(well_top, two, four, material, surface)
	else:
		# outlines the well itself
		addQuad(three, four, well_top, well_side_r, material, surface, false)
		addQuad(well_side_l, well_top, two, one, material, surface, false)
		addTri(four, two, well_top, material, surface)
		
func createBody(surface, halfwidth):
	# link sides
	var fleft_one = Vector3(-halfwidth,0,front)
	var fleft_two = Vector3(-halfwidth,rh,front)
	var fright_one = Vector3(halfwidth,0,front)
	var fright_two = Vector3(halfwidth,rh,front)
	
	#this results in quad visible from inside
	addQuad(fleft_one, fright_one, fright_two, fleft_two, material, surface, false)
	
	addQuad(fleft_two, fright_two, fright_one, fleft_one, material, surface, false)
	
	# front hood
	var fhoodl_one = Vector3(-halfwidth,door_h,0)
	var fhoodr_one = Vector3(halfwidth,door_h,0)
	
	# quad visible from the inside
	addQuad(fleft_two, fright_two, fhoodr_one, fhoodl_one, material, surface, false)
	addQuad(fhoodl_one, fhoodr_one, fright_two, fleft_two, material, surface, false)
	
	# rear hood
	var rhoodl_one = Vector3(-halfwidth,door_h,-door*2)
	var rhoodr_one = Vector3(halfwidth,door_h,-door*2)
	var rear_l = Vector3(-halfwidth,rh,-door*2-rear)
	var rear_r = Vector3(halfwidth,rh,-door*2-rear)
	
	#quad visible from inside
	addQuad(rhoodl_one, rhoodr_one, rear_r, rear_l, material, surface, false)
	addQuad(rear_l, rear_r, rhoodr_one, rhoodl_one, material, surface, false)
	
	# rear
	var rleft_one = Vector3(-halfwidth,0,-door*2-rear)
	var rleft_two = Vector3(-halfwidth,rh,-door*2-rear)
	var rright_one = Vector3(halfwidth,0,-door*2-rear)
	var rright_two = Vector3(halfwidth,rh,-door*2-rear)
	
	addQuad(rleft_one, rright_one, rright_two, rleft_two, material, surface, false)
	# this one is visible from inside
	addQuad(rleft_two, rright_two, rright_one, rleft_one, material, surface, false)
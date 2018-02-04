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

var pillar_w = 0.1

export(SpatialMaterial) var material = SpatialMaterial.new()
export(SpatialMaterial) var glass_material = SpatialMaterial.new()
export(SpatialMaterial) var taillights_material = SpatialMaterial.new()
export(SpatialMaterial) var inside_material = SpatialMaterial.new()
export(SpatialMaterial) var steering_material = SpatialMaterial.new()

func _ready():
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var glass_surf = SurfaceTool.new()
	glass_surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var taillights_surf = SurfaceTool.new()
	taillights_surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var inside_surf = SurfaceTool.new()
	inside_surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("plane")
	add_child(node)
	
	var steering_surf = SurfaceTool.new()
	steering_surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node that will hold the mesh
	var steer_node = MeshInstance.new()
	steer_node.set_name("steering")
	add_child(steer_node)
	
	#do the stuff
	createCar(surface, glass_surf, taillights_surf, inside_surf, node)
	
	var offset = Vector2(0.2,0.55)
	var zoff = -0.1
	createSteeringWheel(steering_surf, steering_material, offset, zoff)
	
	steering_surf.generate_normals()
	steer_node.set_mesh(steering_surf.commit())
	
func createCar(surface, glass, taillights, inside, node):
	# sides
	var halfwidth = float(width/2)

	createSide(surface, -halfwidth, false)
	createSideWindows(glass, glass_material, -halfwidth, false)
	createSide(surface, halfwidth, true)
	createSideWindows(glass, glass_material, halfwidth, true)
	
	#make them visible no matter the side
	createSide(surface, -halfwidth, true)
	createSide(surface, halfwidth, false)
	
	createBody(surface, halfwidth)
	createWindows(glass, glass_material, halfwidth)
	
	createInside(inside, inside_material, halfwidth)
	
	createTailLights(taillights, taillights_material, halfwidth)
	
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
	glass.generate_normals()
	taillights.generate_normals()
	inside.generate_normals()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())
	#Add the other surfaces
	node.set_mesh(glass.commit(node.get_mesh()))
	node.set_mesh(inside.commit(node.get_mesh()))
	node.set_mesh(taillights.commit(node.get_mesh()))
	
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
	
	# side pillars
	#var offset = (-door*2)*0.75
	var r_edge_roof = -door-(roof_w/2)
	var l_edge_roof = -door+(roof_w/2)
	var top_m = Vector3(x_offset,door_h+window_h, -door)
	var top_r = Vector3(x_offset,door_h+window_h, r_edge_roof)
	var top_l = Vector3(x_offset,door_h+window_h, l_edge_roof)
	
	# window coords
	var inner_top_r = Vector3(x_offset, door_h+window_h, r_edge_roof+pillar_w)
	var inner_top_l = Vector3(x_offset, door_h+window_h, l_edge_roof-pillar_w)
	
	var ab = top_r-inner_top_r
	
	var inner_low_l = four+ab
	var inner_low_r = six-ab
	
	if flip:
		addQuad(top_l, inner_top_l, inner_low_l, four, material, surface, false)
		addQuad(inner_top_r, top_r, six, inner_low_r, material, surface, false)
		#addQuad(top_l, top_r, six, four, material, surface, false)
	else:
		addQuad(four, inner_low_l, inner_top_l, top_l, material, surface, false)
		addQuad(inner_low_r, six, top_r, inner_top_r, material, surface, false)
		#addQuad(four, six, top_r, top_l, material, surface, false)

func createSideWindows(surface, mat, x_offset, flip):
	# side windows
	var four = Vector3(x_offset,door_h,0)
	var six = Vector3(x_offset,door_h,-door*2)
	var r_edge_roof = -door-(roof_w/2)
	var l_edge_roof = -door+(roof_w/2)
	var top_r = Vector3(x_offset,door_h+window_h, r_edge_roof)
	
	var inner_top_r = Vector3(x_offset, door_h+window_h, r_edge_roof+pillar_w)
	var inner_top_l = Vector3(x_offset, door_h+window_h, l_edge_roof-pillar_w)
	
	var ab = top_r-inner_top_r
	
	var inner_low_l = four+ab
	var inner_low_r = six-ab
	
	if flip:
		addQuad(inner_top_l, inner_top_r, inner_low_r, inner_low_l, mat, surface, false)
	else:
		addQuad(inner_low_l, inner_low_r, inner_top_r, inner_top_l, mat, surface, false)


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
	
	# front windshield
	var offset = (-door*2)*0.75
	var front_offset = (-door*2)-offset
	var top_win_left = Vector3(-halfwidth,door_h+window_h, -door+(roof_w/2))
	var top_win_right = Vector3(halfwidth, door_h+window_h, -door+(roof_w/2))
	
	var pillar_door_l = Vector3(-halfwidth+0.1, door_h,0)
	var pillar_door_r = Vector3(halfwidth-0.1, door_h,0)
	var pillar_top_l = Vector3(-halfwidth+0.1, door_h+window_h, -door+(roof_w/2))
	var pillar_top_r = Vector3(halfwidth-0.1, door_h+window_h, -door+(roof_w/2))
	
	# pillar A left
	# visible from the inside
	addQuad(fhoodl_one, pillar_door_l, pillar_top_l, top_win_left, material, surface, false)
	addQuad(top_win_left, pillar_top_l, pillar_door_l, fhoodl_one, material, surface, false)
	
	# pillar A right
	# visible from the inside
	addQuad(pillar_door_r, fhoodr_one, top_win_right, pillar_top_r, material, surface, false)
	addQuad(pillar_top_r, top_win_right, fhoodr_one, pillar_door_r, material, surface, false)
	
	# rear pillars
	var top_win_rear_l = Vector3(-halfwidth,door_h+window_h, -door-(roof_w/2))
	var top_win_rear_r = Vector3(halfwidth, door_h+window_h, -door-(roof_w/2))
	var pillar_top_rear_l = Vector3(-halfwidth+0.1, door_h+window_h, -door-(roof_w/2))
	var pillar_top_rear_r = Vector3(halfwidth-0.1, door_h+window_h, -door-(roof_w/2))
	var pillar_bottom_rear_l = Vector3(-halfwidth+0.1, door_h, -door*2)
	var pillar_bottom_rear_r = Vector3(halfwidth-0.1, door_h, -door*2)
	
	#left
	# visible from the inside
	addQuad(rhoodl_one, pillar_bottom_rear_l, pillar_top_rear_l, top_win_rear_l, material, surface, false)
	addQuad(top_win_rear_l, pillar_top_rear_l, pillar_bottom_rear_l, rhoodl_one, material, surface, false)
	
	# right
	addQuad(pillar_bottom_rear_r, rhoodr_one, top_win_rear_r, pillar_top_rear_r, material, surface, false)
	addQuad(pillar_top_rear_r, top_win_rear_r, rhoodr_one, pillar_bottom_rear_r, material, surface, false)

func createWindows(surface, mat, halfwidth):
	# front hood
	var fhoodl_one = Vector3(-halfwidth,door_h,0)
	var fhoodr_one = Vector3(halfwidth,door_h,0)
	# rear hood
	var rhoodl_one = Vector3(-halfwidth,door_h,-door*2)
	var rhoodr_one = Vector3(halfwidth,door_h,-door*2)
	
	# front windshield
	# pillar
	var pillar_door_l = Vector3(-halfwidth+0.1, door_h,0)
	var pillar_door_r = Vector3(halfwidth-0.1, door_h,0)
	var pillar_top_l = Vector3(-halfwidth+0.1, door_h+window_h, -door+(roof_w/2))
	var pillar_top_r = Vector3(halfwidth-0.1, door_h+window_h, -door+(roof_w/2))

	# visible from inside
	addQuad(pillar_door_l, pillar_door_r, pillar_top_r, pillar_top_l, mat, surface, false)
	addQuad(pillar_top_l, pillar_top_r, pillar_door_r, pillar_door_l, mat, surface, false)
	
	# rear windshield
	# rear pillars
	var pillar_top_rear_l = Vector3(-halfwidth+0.1, door_h+window_h, -door-(roof_w/2))
	var pillar_top_rear_r = Vector3(halfwidth-0.1, door_h+window_h, -door-(roof_w/2))
	var pillar_bottom_rear_l = Vector3(-halfwidth+0.1, door_h, -door*2)
	var pillar_bottom_rear_r = Vector3(halfwidth-0.1, door_h, -door*2)
	
	
	var top_win_rear_l = Vector3(-halfwidth,door_h+window_h, -door-(roof_w/2))
	var top_win_rear_r = Vector3(halfwidth, door_h+window_h, -door-(roof_w/2))
	addQuad(pillar_bottom_rear_l, pillar_bottom_rear_r, pillar_top_rear_r, pillar_top_rear_l, mat, surface, false)
	#addQuad(rhoodl_one, rhoodr_one, top_win_rear_r, top_win_rear_l, mat, surface, false)
	# visible from inside
	addQuad(pillar_top_rear_l, pillar_top_rear_r, pillar_bottom_rear_r, pillar_bottom_rear_l, mat, surface, false)
	#addQuad(top_win_rear_l, top_win_rear_r, rhoodr_one, rhoodl_one, mat, surface, false)

	
func createInside(surface, mat, halfwidth):
	var left = Vector3(-halfwidth,0,0)
	var right = Vector3(halfwidth,0,0)
	var fhoodl_one = Vector3(-halfwidth,door_h,0)
	var fhoodr_one = Vector3(halfwidth,door_h,0)
	
	var fhood_med = Vector3(0,door_h+0.1,0)
	
	addQuad(left, right, fhoodr_one, fhoodl_one, mat, surface, false)
	
	# patch the hole
	addTri(fhoodl_one, fhoodr_one, fhood_med, mat, surface)
	
	
	
	# seat
	var seat_w = 0.2
	var seat_off = 0.6
	var back_left_s = Vector3(halfwidth-0.2,0.1,-seat_off)
	var back_right_s = Vector3(halfwidth-0.2-seat_w,0.1,-seat_off)
	var back_topr_s = Vector3(halfwidth-0.2-seat_w,0.75,-seat_off)
	var back_topr_l = Vector3(halfwidth-0.2,0.75,-seat_off)
	
	# from back
	addQuad(back_right_s, back_left_s, back_topr_l, back_topr_s, mat, surface, false)
	addQuad(back_topr_s, back_topr_l, back_left_s, back_right_s, mat, surface, false)
	
	var seat_back_thick = 0.1
	var back_front_l = Vector3(halfwidth-0.2,0.1, -seat_off+seat_back_thick)
	var back_front_r = Vector3(halfwidth-0.2-seat_w, 0.1, -seat_off+seat_back_thick)
	var back_front_top = Vector3(halfwidth-0.2-seat_w, 0.75, -seat_off+seat_back_thick)
	var back_front_top_l = Vector3(halfwidth-0.2, 0.75, -seat_off+seat_back_thick)
	
	addQuad(back_front_r, back_front_l, back_front_top_l, back_front_top, mat, surface, false)
	addQuad(back_front_top, back_front_top_l, back_front_l, back_front_r, mat, surface, false)
	
	# right side
	addQuad(back_front_r, back_right_s, back_topr_s, back_front_top, mat, surface, false)
	addQuad(back_front_top, back_topr_s, back_right_s, back_front_l, mat, surface, false)
	
	# left side
	addQuad(back_front_top_l, back_topr_l, back_left_s, back_front_l, mat, surface, false)
	# from inside
	addQuad(back_front_l, back_left_s, back_topr_l, back_front_top_l, mat, surface, false)
	
	# top
	addQuad(back_topr_s, back_topr_l, back_front_top_l, back_front_top, mat, surface, false) 
	
	var seat_thick = 0.2
	var seat_front_r = Vector3(halfwidth-0.2-seat_w, 0.1, -seat_off+seat_back_thick+seat_thick)
	var seat_front_l = Vector3(halfwidth-0.2, 0.1, -seat_off+seat_back_thick+seat_thick)
	var seat_top_l = Vector3(halfwidth-0.2, 0.3, -seat_off+seat_back_thick+seat_thick)
	var seat_top_r = Vector3(halfwidth-0.2-seat_w, 0.3, -seat_off+seat_back_thick+seat_thick)
	
	# from back
	addQuad(seat_front_r, seat_front_l, seat_top_l, seat_top_r, mat, surface, false)
	addQuad(seat_top_r, seat_top_l, seat_front_l, seat_front_r, mat, surface, false)
	
	var tie_r = Vector3(halfwidth-0.2-seat_w, 0.3, -seat_off+seat_back_thick)
	var tie_l = Vector3(halfwidth-0.2, 0.3, -seat_off+seat_back_thick)
	
	# side
	addQuad(tie_r, seat_top_r, seat_front_r, back_front_r, mat, surface, false)
	# from inside
	addQuad(back_front_r, seat_front_r, seat_top_r, tie_r, mat, surface, false)
	
	# left side
	addQuad(back_front_l, seat_front_l, seat_top_l, tie_l, mat, surface, false)
	
	# top of seat
	addQuad(tie_r, tie_l, seat_top_l, seat_top_r, mat, surface, false)
	
func createSteeringWheel(surface, mat, offset, z_off):
	# circle
	#var circle = make_circle(Vector2(offset), 16, 0.1)
	
	#for i in range(0, circle.size()-1):	
	#	addTri(Vector3(offset.x, offset.y, z_off), Vector3(circle[i].x, circle[i].y, z_off), Vector3(circle[i+1].x, circle[i+1].y, z_off), mat, surface)

	# rectangle
	var one = Vector3(offset.x-0.1, offset.y, z_off)
	var two = Vector3(offset.x+0.1, offset.y, z_off)
	var three = Vector3(offset.x+0.1, offset.y+0.1, z_off)
	var four = Vector3(offset.x-0.1, offset.y+0.1, z_off)
	
	addQuad(one, two, three, four, mat, surface, false)

	# the side
	addQuad(Vector3(one.x, one.y, z_off+0.01), one, four, Vector3(four.x, four.y, z_off+0.01), mat, surface, false)
	# other side
	addQuad(two, Vector3(two.x, two.y, z_off+0.01), Vector3(three.x, three.y, z_off+0.01), three, mat, surface, false)

	# top
	addQuad(four, three, Vector3(three.x, three.y, z_off+0.01), Vector3(four.x, four.y, z_off+0.01), mat, surface, false)
	
	
	#bottom 
	addQuad(Vector3(one.x, one.y, z_off+0.01), Vector3(two.x, two.y, z_off+0.01), two, one, mat, surface, false)
	#(from the top)
	addQuad(one, two, Vector3(two.x, two.y, z_off+0.01), Vector3(one.x, one.y, z_off+0.01), mat, surface, false)
	

	# the back 
	addQuad(Vector3(four.x, four.y, z_off+0.01), Vector3(three.x, three.y, z_off+0.01), Vector3(two.x, two.y, z_off+0.01), Vector3(one.x, one.y, z_off+0.01), mat, surface, false)
	# from the front
	addQuad(Vector3(one.x, one.y, z_off+0.01), Vector3(two.x, two.y, z_off+0.01), Vector3(three.x, three.y, z_off+0.01), Vector3(four.x, four.y, z_off+0.01), mat, surface, false)

func createTailLights(surface, mat, halfwidth):
	# right light
	var light_off =0.02
	var light_one_l = Vector3(-halfwidth+0.2,0.1, -door*2-rear-light_off)
	var light_one_top_l = Vector3(-halfwidth+0.2,0.2, -door*2-rear-light_off)
	var light_one_r = Vector3(-halfwidth+0.4,0.1, -door*2-rear-light_off)
	var light_one_top_r = Vector3(-halfwidth+0.4,0.2, -door*2-rear-light_off)
	
	addQuad(light_one_l, light_one_r, light_one_top_r, light_one_top_l, mat, surface, false)
	
	# left light
	var light_two_l = Vector3(halfwidth-0.2,0.1, -door*2-rear-light_off)
	var light_two_top_l = Vector3(halfwidth-0.2,0.2, -door*2-rear-light_off)
	var light_two_r = Vector3(halfwidth-0.4,0.1, -door*2-rear-light_off)
	var light_two_top_r = Vector3(halfwidth-0.4,0.2, -door*2-rear-light_off)
	
	# seen from inside
	#addQuad(light_two_l, light_two_r, light_two_top_r, light_two_top_l, mat, surface, false)
	addQuad(light_two_top_l, light_two_top_r, light_two_r, light_two_l, mat, surface, false)
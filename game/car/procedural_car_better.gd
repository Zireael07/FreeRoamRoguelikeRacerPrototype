tool
#extends Node
extends "res://scripts/mesh_gen.gd"

# class member variables go here, for example:
	
#export(PoolVector2Array) var polygon
#export(PoolVector2Array) var window_poly

var polygon = []
var window_poly = []

export(float) var width = 1.0

var indices = []
var indices_top = []
var indices_front = []
var indices_rear = []


var indices_body = []
	
export(SpatialMaterial) var material = SpatialMaterial.new()
export(SpatialMaterial) var glass_material = SpatialMaterial.new()
export(SpatialMaterial) var steering_material = SpatialMaterial.new()

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here.	
	
	var trueno_side_window = [Vector2(0.102906, 0.489506), Vector2(0.45022, 0.745425), Vector2(1.13577, 0.741807), Vector2(1.19646, 0.511102)]
	window_poly = trueno_side_window
	
	var trueno = [Vector2(-0.764126, 0.07102), Vector2(-0.587397, 0.011519), Vector2(-0.456753, -0.004075), Vector2(-0.338316, 0.180084), Vector2(-0.20599, 0.293982), Vector2(-0.083261, 0.209353), Vector2(-0.03591, 0.106849), 
	Vector2(-0.036215, 0.007574), Vector2(1.15943, 0.007378), Vector2(1.1816, 0.145438), Vector2(1.28406, 0.247247), Vector2(1.38462, 0.288478), 
	Vector2(1.56198, 0.060509), Vector2(1.83474, 0.060503), Vector2(1.88706, 0.297294), Vector2(1.81217, 0.563924), Vector2(1.59168, 0.581192), Vector2(1.47597, 0.635872), Vector2(1.19123, 0.778995), Vector2(0.419381, 0.784911), Vector2(-0.04922, 0.452933), Vector2(-0.338839, 0.437128), Vector2(-0.743482, 0.322674)]

	#polygon = trueno
	polygon.resize(0)


	# this is just the outline: 0-13-15-22
	polygon.append(trueno[0]) # -0.764126 #beginning
	# front wheel well
	polygon.append(trueno[2]) # -0.4567
	polygon.append(trueno[3]) # -0.33
	# top of wheel well
	polygon.append(trueno[4]) #-0.20
	polygon.append(trueno[5]) # -0.08
	polygon.append(trueno[7]) # -0.03
	
	# rear wheel well
	polygon.append(trueno[8]) # 1.15943
	polygon.append(trueno[9]) # 1.1816
	#polygon.append(trueno[10]) # 1.28406
	# top of wheel well
	polygon.append(trueno[11]) # 1.38462
	# missing point in original
	polygon.append((trueno[12]+trueno[11])/2) # midpoint
	polygon.append(trueno[12]) # 1.56198
	
	# the rear
	polygon.append(trueno[13]) # 1.83
	polygon.append(trueno[14]) # the kink in the rear - 1.88706
	polygon.append(trueno[15]) # 1.81
	# top part
	polygon.append(trueno[18]) # 1.19123
	polygon.append(trueno[19]) # 0.41938
	polygon.append(trueno[20]) # -0.04
	polygon.append(trueno[22]) # -0.74 #end
	
	
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var glass_surf = SurfaceTool.new()
	glass_surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var inside_surf = SurfaceTool.new()
	inside_surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("plane")
	add_child(node)
	
	var steering_surf = SurfaceTool.new()
	steering_surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node that will hold the mesh
	var steer_node = MeshInstance.new()
	steer_node.set_name("steering")
	add_child(steer_node)
	
	if polygon.size() < 1:
		return
		
	#print(str(polygon))
	#polygon.invert()
	
	createCar(trueno, window_poly, surface, glass_surf)
	
	createSteeringWheel(steering_surf, steering_material)
	
	steering_surf.generate_normals()
	steering_surf.set_material(steering_material)
	steer_node.set_mesh(steering_surf.commit())
	
	
	# finish
	surface.generate_normals()
	surface.set_material(material)
	glass_surf.generate_normals()
	glass_surf.set_material(glass_material)
	
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())
	#Add the other surfaces
	node.set_mesh(glass_surf.commit(node.get_mesh()))
	
	
	#pass

func createSteeringWheel(steering_surf, steering_material):
	var side_poly = []
	
	# these values seem to fit the Trueno outline - it's roughly the position of the window bottom left
	
	# TODO: define x,y,z of the center and work from that
	
	side_poly.append(Vector2(0.15, 0.40))
	side_poly.append(Vector2(0.18, 0.40))
	side_poly.append(Vector2(0.18, 0.50))
	side_poly.append(Vector2(0.15, 0.50))
	
	var indices = Array(Geometry.triangulate_polygon(PoolVector2Array(side_poly)))
	
	# 0.2 and 0.4 make a right-hand drive
	
	createSide(indices, side_poly, steering_surf, 0.58)
	createSide(indices, side_poly, steering_surf, 0.58, true)
	createSide(indices, side_poly, steering_surf, 0.78, true)
	createSide(indices, side_poly, steering_surf, 0.78)
	
	linkSides(indices, side_poly, steering_surf, 0.58, 0.78, true)
	
	# add missing top
	var p0 = side_poly[2]
	var p1 = side_poly[3]
	
	print(str(p0))
	print(str(p1))
	
	createQuadNoUV(steering_surf, Vector3(p0.x, p0.y, 0.58), Vector3(p0.x, p0.y, 0.78), Vector3(p1.x, p1.y, 0.78), Vector3(p1.x, p1.y, 0.58))
	createQuadNoUV(steering_surf, Vector3(p0.x, p0.y, 0.58), Vector3(p0.x, p0.y, 0.78), Vector3(p1.x, p1.y, 0.78), Vector3(p1.x, p1.y, 0.58), true)
	
func createCar(trueno, window_poly, surface, glass_surf):
	var poly_bottom = []
	poly_bottom.append(trueno[7]) # end of front wheel well
	poly_bottom.append(trueno[8]) # beginning of rear wheel well
	poly_bottom.append(window_poly[3]) # bottom right of window
	poly_bottom.append(window_poly[0]) # bottom left of window
	
	indices = Array(Geometry.triangulate_polygon(PoolVector2Array(poly_bottom)))
	#print("Indices" + str(indices))
	
	var poly_top = []
	poly_top.append(window_poly[0]) # bottom left
	poly_top.append(window_poly[1]) # top left
	poly_top.append(window_poly[2]) # top right
	# car top, right to left
	poly_top.append(trueno[18])
	poly_top.append(trueno[19])
	poly_top.append(trueno[20])
	
	indices_top = Array(Geometry.triangulate_polygon(PoolVector2Array(poly_top)))
	
	var poly_front = []
	for i in range(0, 7):
		poly_front.append(polygon[i])
		
	poly_front.append(window_poly[0])
	poly_front.append(polygon[polygon.size()-2])
	poly_front.append(polygon[polygon.size()-1])
	
	indices_front = Array(Geometry.triangulate_polygon(PoolVector2Array(poly_front)))
	
	var poly_rear = []
	for i in range(6, 15):
		poly_rear.append(polygon[i])
	
	poly_rear.append(window_poly[2]) # top right
	poly_rear.append(window_poly[3]) # bottom right
	
	indices_rear = Array(Geometry.triangulate_polygon(PoolVector2Array(poly_rear)))
	#print(str(indices_rear))
	
	# build car
	createSide(indices, poly_bottom, surface, 0)
	createSide(indices_top, poly_top, surface, 0)
	createSide(indices_front, poly_front, surface, 0)
	createSide(indices_rear, poly_rear, surface, 0)
	#other side
#	createSide(indices, poly_bottom, surface, 0, true)
#	createSide(indices_top, poly_top, surface, 0, true)
#	createSide(indices_front, poly_front, surface, 0, true)
#	createSide(indices_rear, poly_rear, surface, 0, true)
	
	createSide(indices, poly_bottom, surface, width, true)
	createSide(indices_top, poly_top, surface, width, true)
	createSide(indices_front, poly_front, surface, width, true)
	createSide(indices_rear, poly_rear, surface, width, true)
	#other side
#	createSide(indices, poly_bottom, surface, width, false)
#	createSide(indices_top, poly_top, surface, width, false)
#	createSide(indices_front, poly_front, surface, width, false)
#	createSide(indices_rear, poly_rear, surface, width, false)
	
	
	createSideWindow(window_poly, glass_surf, 0, true)
	#createSideWindow(window_poly, glass_surf, 0, false)
	# other side
	createSideWindow(window_poly, glass_surf, width)
#	createSideWindow(window_poly, glass_surf, width, true)
	
	createRear(surface, glass_surf)
	
	createFront(surface, glass_surf)
	
	# add missing parts (hood, roof) due to exclusion below	
	# hood
	var p = polygon.size()-2
	var p0 = polygon[p]
	var p1 = polygon[p+1]
	
	createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0))
	#createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0), true)
	
	# roof
	p = polygon.size()-4
	p0 = polygon[p]
	p1 = polygon[p+1]
	
	createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0))
	#createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0), true)
	
	
	# we need to exclude the parts where the front/rear windows go (see above)
	var psize = polygon.size()
	polygon.remove(psize-2)
	polygon.remove(psize-3)
	polygon.remove(psize-4)
	
	
	indices_body = Array(Geometry.triangulate_polygon(PoolVector2Array(polygon)))
	
	#print("Indices: " + str(indices_body))
	linkSides(indices_body, polygon, surface, width)
	
	# add missing front
	p0 = polygon[0]
	p1 = polygon[polygon.size()-1]
	
	createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0))
	#createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0), true)


# TODO: write a common function for both front and rear (90% of logic is duplicated)
func calculateFrontWindow():
	var index = 2
	
	var p0 = Vector3(polygon[polygon.size()-index].x, polygon[polygon.size()-index].y, 0)
	var p1 = Vector3(polygon[polygon.size()-index].x, polygon[polygon.size()-index].y, width)
	var p2 = Vector3(polygon[polygon.size()-(index+1)].x, polygon[polygon.size()-(index+1)].y, 0)
	var p3 = Vector3(polygon[polygon.size()-(index+1)].x, polygon[polygon.size()-(index+1)].y, width)
	
	# line between A and B = B-A
	var front_line = (p1 - p0)
	var upper_line = (p3 - p2)
	var angle_line = (p2 - p0)
	
	# to decide x/y placement
	var angle_bottom = p0 + angle_line*0.2
	var angle_top = p0 + angle_line*0.9
	
	# z placement
	var left_bottom = p0 + front_line*0.05
	var right_bottom = p0 + front_line*0.95	

	var left_top = p2 + upper_line*0.05
	var right_top = p2 + upper_line*0.95
	
	var front_window_poly = [
	Vector3(angle_bottom.x, angle_bottom.y, left_bottom.z),
	Vector3(angle_bottom.x, angle_bottom.y, right_bottom.z),
	Vector3(angle_top.x, angle_top.y, right_top.z),
	Vector3(angle_top.x, angle_top.y, left_top.z)
	]
	
	return front_window_poly

func createFront(surface, glass_surf):
	var front_window_poly = calculateFrontWindow()	
	
	createWindow(front_window_poly, glass_surf)
	#createWindow(front_window_poly, glass_surf, true)
	
	var bottom_front = []
	bottom_front.append(Vector3(polygon[polygon.size()-2].x, polygon[polygon.size()-2].y, 0))
	bottom_front.append(Vector3(polygon[polygon.size()-2].x, polygon[polygon.size()-2].y, width))
	bottom_front.append(front_window_poly[1])
	bottom_front.append(front_window_poly[0])
	
	createQuadNoUV(surface, bottom_front[0], bottom_front[1], bottom_front[2], bottom_front[3])
	#createQuadNoUV(surface, bottom_front[0], bottom_front[1], bottom_front[2], bottom_front[3], true)
	
	var top_front = []
	top_front.append(front_window_poly[2])
	top_front.append(front_window_poly[3])
	top_front.append(Vector3(polygon[polygon.size()-3].x, polygon[polygon.size()-3].y, 0))
	top_front.append(Vector3(polygon[polygon.size()-3].x, polygon[polygon.size()-3].y, width))
	
	createQuadNoUV(surface, top_front[0], top_front[1], top_front[2], top_front[3])
	#createQuadNoUV(surface, top_front[0], top_front[1], top_front[2], top_front[3], true)
	
	var front_pillar_left = []
	front_pillar_left.append(bottom_front[0])
	front_pillar_left.append(bottom_front[3])
	front_pillar_left.append(top_front[1])
	front_pillar_left.append(top_front[2])
	
	createQuadNoUV(surface, front_pillar_left[0], front_pillar_left[1], front_pillar_left[2], front_pillar_left[3])
	#createQuadNoUV(surface, front_pillar_left[0], front_pillar_left[1], front_pillar_left[2], front_pillar_left[3], true)
	
	var front_pillar_right = []
	front_pillar_right.append(bottom_front[1])
	front_pillar_right.append(bottom_front[2])
	front_pillar_right.append(top_front[0])
	front_pillar_right.append(top_front[3])
	
	createQuadNoUV(surface, front_pillar_right[0], front_pillar_right[1], front_pillar_right[2], front_pillar_right[3])
	#createQuadNoUV(surface, front_pillar_right[0], front_pillar_right[1], front_pillar_right[2], front_pillar_right[3], true)
	
func calculateRearWindow():
	var index = 5
	
	var p0 = Vector3(polygon[polygon.size()-index].x, polygon[polygon.size()-index].y, 0)
	var p1 = Vector3(polygon[polygon.size()-index].x, polygon[polygon.size()-index].y, width)
	var p2 = Vector3(polygon[polygon.size()-(index-1)].x, polygon[polygon.size()-(index-1)].y, 0)
	var p3 = Vector3(polygon[polygon.size()-(index-1)].x, polygon[polygon.size()-(index-1)].y, width)
	
	# line between A and B = B-A
	var rear_line = (p1 - p0)
	var upper_line = (p3 - p2)
	var angle_line = (p2 - p0)
	
	# to decide x/y placement
	var angle_bottom = p0 + angle_line*0.5
	var angle_top = p0 + angle_line*0.9
	
	# z placement
	var left_bottom = p0 + rear_line*0.05
	var right_bottom = p0 + rear_line*0.95
	
	var left_top = p2 + upper_line*0.05
	var right_top = p2 + upper_line*0.95
	
	var rear_window_poly = [
	Vector3(angle_bottom.x, angle_bottom.y, left_bottom.z),
	Vector3(angle_bottom.x, angle_bottom.y, right_bottom.z),
	Vector3(angle_top.x, angle_top.y, right_top.z),
	Vector3(angle_top.x, angle_top.y, left_top.z)
	]
	
	return rear_window_poly

func createRear(surface, glass_surf):
	var rear_window_poly = calculateRearWindow()	
	
	createWindow(rear_window_poly, glass_surf)
	#createWindow(rear_window_poly, glass_surf, true)
	
	# fill the rest of the body
	var bottom_rear = []
	bottom_rear.append(Vector3(polygon[polygon.size()-5].x, polygon[polygon.size()-5].y, 0))
	bottom_rear.append(Vector3(polygon[polygon.size()-5].x, polygon[polygon.size()-5].y, width))
	bottom_rear.append(rear_window_poly[1])
	bottom_rear.append(rear_window_poly[0])
	
	createQuadNoUV(surface, bottom_rear[0], bottom_rear[1], bottom_rear[2], bottom_rear[3])
	#createQuadNoUV(surface, bottom_rear[0], bottom_rear[1], bottom_rear[2], bottom_rear[3], true)
	
	var top_rear = []
	top_rear.append(rear_window_poly[2])
	top_rear.append(rear_window_poly[3])
	top_rear.append(Vector3(polygon[polygon.size()-4].x, polygon[polygon.size()-4].y, 0))
	top_rear.append(Vector3(polygon[polygon.size()-4].x, polygon[polygon.size()-4].y, width))
	
	createQuadNoUV(surface, top_rear[0], top_rear[1], top_rear[2], top_rear[3])
	#createQuadNoUV(surface, top_rear[0], top_rear[1], top_rear[2], top_rear[3], true)
	
	var rear_pillar_left = []
	rear_pillar_left.append(bottom_rear[0])
	rear_pillar_left.append(bottom_rear[3])
	rear_pillar_left.append(top_rear[1])
	rear_pillar_left.append(top_rear[2])
	
	createQuadNoUV(surface, rear_pillar_left[0], rear_pillar_left[1], rear_pillar_left[2], rear_pillar_left[3])
	#createQuadNoUV(surface, rear_pillar_left[0], rear_pillar_left[1], rear_pillar_left[2], rear_pillar_left[3], true)
	
	var rear_pillar_right = []
	rear_pillar_right.append(bottom_rear[1])
	rear_pillar_right.append(bottom_rear[2])
	rear_pillar_right.append(top_rear[0])
	rear_pillar_right.append(top_rear[3])
	
	createQuadNoUV(surface, rear_pillar_right[0], rear_pillar_right[1], rear_pillar_right[2], rear_pillar_right[3])
	#createQuadNoUV(surface, rear_pillar_right[0], rear_pillar_right[1], rear_pillar_right[2], rear_pillar_right[3], true)

func createQuadNoUV(surface, one, two, three, four, flip=false):
	if not flip:
		surface.add_vertex(one) #0
		surface.add_vertex(two) #1
		surface.add_vertex(three) #2
		surface.add_vertex(three) #2
		surface.add_vertex(four) #3
		surface.add_vertex(one) #0
	else:
		surface.add_vertex(one) #0
		surface.add_vertex(four) #3
		surface.add_vertex(three) #2
		surface.add_vertex(three) #2
		surface.add_vertex(two) #1
		surface.add_vertex(one) #0
	
	#print("Created quad")

func createSide(indices, poly, surface, offset, flip=false):
	if indices.empty():
		return
		
	if flip:
		# prevents weirdness
		var dup = indices.duplicate()
		dup.invert()
		#print("Indices after flip: " + str(dup))
		indices = dup	
		
	for i in indices:
		surface.add_vertex(Vector3(poly[i].x, poly[i].y, offset))
		#surface.add_vertex(Vector3(polygon[i].x, polygon[i].y, offset))
		
func createSideWindow(window_verts, surface, offset, flip=false):
	# assume that the window is made of four vertices
	if window_verts.size() < 4:
		return
	
	var one = Vector3(window_verts[0].x, window_verts[0].y, offset)
	var two = Vector3(window_verts[1].x, window_verts[1].y, offset)
	var three = Vector3(window_verts[2].x, window_verts[2].y, offset)
	var four = Vector3(window_verts[3].x, window_verts[3].y, offset)
	
	
	#print("Creating side window...")
	createQuadNoUV(surface, one, two, three, four, flip)

func createWindow(window_verts, surface, flip=false):
	# assume that the window is made of four vertices
	if window_verts.size() < 4:
		return
		
	var one = window_verts[0]
	var two = window_verts[1]
	var three = window_verts[2]
	var four = window_verts[3]
	
	createQuadNoUV(surface, one, two, three, four, flip)

		
func linkSides(indices, polygon, surface, offset, begin=0, dup=false):
	for p in range(0, polygon.size()):
		var p0 = polygon[p]
		if polygon.size() > p+2:
			var p1 = polygon[p+1]
			#print("Linking" + str(p0) + " + " + str(p1))
		
			createQuadNoUV(surface, Vector3(p0.x, p0.y, begin), Vector3(p0.x, p0.y, offset), Vector3(p1.x, p1.y, offset), Vector3(p1.x, p1.y, begin))
			if dup:
				createQuadNoUV(surface, Vector3(p0.x, p0.y, begin), Vector3(p0.x, p0.y, offset), Vector3(p1.x, p1.y, offset), Vector3(p1.x, p1.y, begin), true)
		
		
		#addQuad(Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, offset), Vector3(p1.x, p1.y, offset), Vector3(p1.x, p1.y, 0), material, surface, false) 
		
		

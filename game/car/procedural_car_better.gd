tool
extends "res://scripts/mesh_gen.gd"

# class member variables go here, for example:

var car_front = []
var car_rear = []
var window_poly = []

export(float) var width = 1.0

var indices = []
var indices_top = []
var indices_front = []
var indices_rear = []


var indices_body = []
	
export(SpatialMaterial) var material = SpatialMaterial.new()
export(ShaderMaterial) var glass_material = ShaderMaterial.new()
export(SpatialMaterial) var steering_material = SpatialMaterial.new()

var rain_glass_mat
var car_surface = null

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here.	
	
	rain_glass_mat = preload("res://assets/shadermaterial_glass_rain.tres")
	
	if Engine.is_editor_hint():
		var car = defineCar()
		
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
		get_node("Spatial").add_child(steer_node)
		
		#Turn off shadows
		steer_node.set_cast_shadows_setting(0)
		
		# magic happens here!
		createCar(car_front, car_rear, car, window_poly, surface, glass_surf)
		
		createSteeringWheel(steering_surf, steering_material)
		
		steering_surf.generate_normals()
		steering_surf.set_material(steering_material)
		steer_node.set_mesh(steering_surf.commit())
		
		# name mats
		glass_material.set_name("Glass")
		material.set_name("Body")
		
		# finish
		surface.generate_normals()
		surface.set_material(material)
		glass_surf.generate_normals()
		glass_surf.set_material(glass_material)
		
		
		#Set the created mesh to the node
		node.set_mesh(surface.commit())
		#Add the other surfaces
		node.set_mesh(glass_surf.commit(node.get_mesh()))
		
		# store the surface because it'll be used later
		car_surface = surface
		
		# post-process
		node.get_mesh().surface_set_name(0, "body")
		node.get_mesh().surface_set_name(1, "glass")
		
		# save
		# Saves mesh to a .tres file with compression enabled.
		# one-time
		#ResourceSaver.save("res://save_test.tres", node.get_mesh(), 32)

func defineCar():
	# bottom left, top left, top right, bottom right
	var trueno_side_window = [Vector2(0.102906, 0.489506), Vector2(0.45022, 0.745425), Vector2(1.13577, 0.741807), Vector2(1.19646, 0.511102)]
	#window_poly = trueno_side_window
	
	# 5 entries in first row, 2 (originally 7 in one row), five each in the next, all the rest	
#	var trueno = [Vector2(-0.764126, 0.07102), Vector2(-0.587397, 0.011519), Vector2(-0.456753, -0.004075), Vector2(-0.338316, 0.180084), Vector2(-0.20599, 0.293982), 
#	Vector2(-0.083261, 0.209353), Vector2(-0.03591, 0.106849),
#	Vector2(-0.036215, 0.007574), Vector2(1.15943, 0.007378), Vector2(1.1816, 0.145438), Vector2(1.28406, 0.247247), Vector2(1.38462, 0.288478),
#	Vector2(1.56198, 0.060509), Vector2(1.83474, 0.060503), Vector2(1.88706, 0.297294), Vector2(1.81217, 0.563924), Vector2(1.59168, 0.581192),
#	Vector2(1.47597, 0.635872), Vector2(1.19123, 0.778995), Vector2(0.419381, 0.784911), Vector2(-0.04922, 0.452933), Vector2(-0.338839, 0.437128), 
#	Vector2(-0.743482, 0.322674)]


	# instead of one huge array, let's work on several smaller ones
	var trueno_front = [Vector2(-0.764126, 0.07102), Vector2(-0.456753, -0.004075), Vector2(-0.338316, 0.180084), Vector2(-0.20599, 0.293982), 
	Vector2(-0.083261, 0.209353), Vector2(-0.036215, 0.007574),
# top part
	Vector2(0.419381, 0.784911), Vector2(-0.04922, 0.452933), Vector2(-0.743482, 0.322674)
	]

#	# missing points for wheel wells trueno
#	var val1 = (trueno_front[2]+trueno_front[1])/2 # midpoint
#	var val2 = (trueno_front[5]+trueno_front[4])/2 # midpoint
#	var add = [[3, val1], [6, val2]] #need to remember that the first point is inserted already, so the index is increased by 1
#
#	for i in range(add.size()):
#		var p = add[i]
#		trueno_front.insert(p[0], p[1])
#
	# bottom left, top left, top right, bottom right
	var yris_side_window = [Vector2(0.166, 0.3415), Vector2(0.166, 0.4015), Vector2(1.44, 0.4715), Vector2(1.45, 0.3715), ]

	# bottom front [0], the next seven describe a wheel well 
	# [1].y < [2].y < [3].y < [4].y > [5].y > [6].y > [7].y and same for x (they angle up and then down)
	var yris_front = [ Vector2(-0.52375, 0), Vector2(-0.338125, 0.003375), Vector2(-0.338125, 0.029), Vector2(-0.32125, 0.14175), Vector2(-0.22675, 0.20626), 
	Vector2(-0.142375, 0.189), Vector2(-0.06475, 0.097875), Vector2(-0.0445, 0),
	# top part
	# this is the point above the window (so x > window left edge and y > window top edge)
	Vector2(0.21875, 0.513),
	Vector2(0.09175, 0.361125), Vector2(-0.355, 0.31725), Vector2(-0.486625, 0.26325),  Vector2(-0.5305, 0.205875), Vector2(-0.544, 0.104625)
	]

	window_poly = yris_side_window
	car_front = yris_front

	# windows
	var front_wheel_end = 7
	
	# split edge to avoid problems polygonizing when windows are involved
	var tmp = (car_front[9]+car_front[8])/2 # midpoint
	car_front.insert(9, tmp)
	
	# inverted because the second insertion pushes the first forward
	car_front.insert(front_wheel_end+1, window_poly[1])
	car_front.insert(front_wheel_end+1, window_poly[0])


	var trueno_rear = [Vector2(1.15943, 0.007378), Vector2(1.1816, 0.145438), Vector2(1.28406, 0.247247), Vector2(1.38462, 0.288478),
	Vector2(1.56198, 0.060509), Vector2(1.83474, 0.060503), Vector2(1.88706, 0.297294), Vector2(1.81217, 0.563924), Vector2(1.59168, 0.581192),
	Vector2(1.47597, 0.635872), Vector2(1.19123, 0.778995)
	]

	car_rear = trueno_rear
	# missing wheel well points
	var val3 = (car_rear[4]+car_rear[3])/2 # midpoint
	car_rear.insert(4, val3)
	var val4 = (car_rear[5]+car_rear[4])/2 # midpoint
	car_rear.insert(5, val4)

	# split final edge to avoid problems polygonizing when windows are involved
	tmp = (car_rear[0]+car_rear[car_rear.size()-1])/2 # midpoint
	car_rear.append(tmp)
		
	# windows
	# because the final point is the midpoint
	var i = car_rear.size()-1
	# top right, bottom right
	# inverted because the second insertion pushes the first forward
	car_rear.insert(i, window_poly[3])
	car_rear.insert(i, window_poly[2])

	var car = []
	
#	# trueno skips some points
#	var skip = [1,6,10, trueno.size()-2]
#	for i in range(trueno.size()):
#		if not skip.has(i):
#			car.append(trueno[i])

	# exclude windows
	for i in range(car_front.size()):
		if not window_poly.has(car_front[i]):
			car.append(car_front[i])

	# exclude windows
	for i in range(car_rear.size()):
		if not window_poly.has(car_rear[i]):
			car.append(car_rear[i])	
	
	print("Car final id: " + str(car.size()-1))
	
		
	#	# bottom front point
	#	polygon.append(car[0]) # -0.764126 #beginning
	#
	#	# front wheel well
	#	# two points between wheel well bottom and top
	#	polygon.append(car[1]) # -0.4567
	#	polygon.append(car[2]) # -0.33
	#	polygon.append(car[3])
	#	# top of wheel well
	#	polygon.append(car[4]) #-0.20
	#	polygon.append(car[5])
	#	polygon.append(car[6]) # -0.08
	#	polygon.append(car[7]) # -0.03
		
	#	# rear wheel well
	#	# two points between wheel well bottom and top
	#	polygon.append(car[8]) # 1.15943
	#	polygon.append(car[9]) # 1.1816
	#	polygon.append(car[10])
	#	# top of wheel well
	#	polygon.append(car[11]) # 1.38462
	#	polygon.append(car[12])
	#	polygon.append(car[13])
	#	polygon.append(car[14]) # 1.56198
		
		# the rear
	#	var rear_length = 2
	#	polygon.append(car[15]) # 1.83
	#	for i in range(1, rear_length+1): # because it's not inclusive
	#		#print(str(i))
	#		polygon.append(car[15+i])
				
	#	polygon.append(car[16]) # the kink in the rear - 1.88706
	#	polygon.append(car[17]) # 1.81
		
		# top part
	#	var top_length = 3
	#	for i in range(top_length, 0, -1): # inverted is inclusive for some reason
	#		#print(str(i) + " " + str(-1-i) + " " + str(car.size()-1-i))
	#		polygon.append(car[car.size()-1-i])
		#polygon.append(car[car.size()-4]) # 1.19123
		#polygon.append(car[car.size()-3]) # 0.41938
		#polygon.append(car[car.size()-2]) # -0.04
		
		# closes the polygon
	#	polygon.append(car[car.size()-1]) # -0.74 #end
		
		#print("Polygon final id: " + str(polygon.size()-1))
		
	return car

func createSteeringWheel(steering_surf, steering_material):
	var side_poly = []
	
	# these values seem to fit the Trueno outline - it's roughly the position of the window bottom left
	
	side_poly.append(Vector2(-0.015, -0.05))
	side_poly.append(Vector2(0.015, -0.05))
	side_poly.append(Vector2(0.015, 0.05))
	side_poly.append(Vector2(-0.015, 0.05))
	
	var indices = Array(Geometry.triangulate_polygon(PoolVector2Array(side_poly)))
	
	createSide(indices, side_poly, steering_surf, -0.1)
	createSide(indices, side_poly, steering_surf, -0.1, true)
	createSide(indices, side_poly, steering_surf, 0.1, true)
	createSide(indices, side_poly, steering_surf, 0.1)
	
	linkSides(indices, side_poly, steering_surf, -0.1, 0.1, true)
	
	# add missing top
	var p0 = side_poly[2]
	var p1 = side_poly[3]
	
	print(str(p0))
	print(str(p1))
	
	createQuadNoUV(steering_surf, Vector3(p0.x, p0.y, -0.1), Vector3(p0.x, p0.y, 0.1), Vector3(p1.x, p1.y, 0.1), Vector3(p1.x, p1.y, -0.1))
	createQuadNoUV(steering_surf, Vector3(p0.x, p0.y, -0.1), Vector3(p0.x, p0.y, 0.1), Vector3(p1.x, p1.y, 0.1), Vector3(p1.x, p1.y, -0.1), true)
	
func createCar(car_front, trueno_rear, car, window_poly, surface, glass_surf):
	# make the bottom
	var front_wheel_end = 7
	var poly_bottom = []
	poly_bottom.append(car_front[front_wheel_end]) # end of front wheel well
	poly_bottom.append(trueno_rear[0]) # beginning of rear wheel well
	poly_bottom.append(window_poly[3]) # bottom right of window
	poly_bottom.append(window_poly[0]) # bottom left of window
	
	indices = Array(Geometry.triangulate_polygon(PoolVector2Array(poly_bottom)))
	#print("Indices" + str(indices))
	
	# make the top
	var poly_top = []
	# if top too low, don't make it (cabrio)
	if car_front[front_wheel_end+3].y > 0.6:	
		poly_top.append(window_poly[1]) # top left
		poly_top.append(window_poly[2]) # top right
		# car top, right to left
		# this should be higher (y>y1) than window top
		poly_top.append(trueno_rear[trueno_rear.size()-4])
		poly_top.append(car_front[front_wheel_end+3]) # the point above the front windows
		
		indices_top = Array(Geometry.triangulate_polygon(PoolVector2Array(poly_top)))
		# error message if something went wrong
		if indices_top.size() < 1:
			print("Top polygon couldn't be triangulated!")
	
	# front polygon
	var poly_front = []
	poly_front = car_front


	indices_front = Array(Geometry.triangulate_polygon(PoolVector2Array(poly_front)))
	# error message if something went wrong
	if indices_front.size() < 1:
		print("Front polygon couldn't be triangulated!")
	
	# rear polygon
	var poly_rear = []
	poly_rear = trueno_rear

	
	indices_rear = Array(Geometry.triangulate_polygon(PoolVector2Array(poly_rear)))
	# error message if something went wrong
	if indices_rear.size() < 1:
		print("Front polygon couldn't be triangulated!")
	#print(str(indices_rear))
	
	# build car
	createSide(indices, poly_bottom, surface, 0)
	# if top too low, don't make it (cabrio)
	if car_front[front_wheel_end+3].y > 0.6:
		createSide(indices_top, poly_top, surface, 0)
	createSide(indices_front, poly_front, surface, 0)
	createSide(indices_rear, poly_rear, surface, 0)
	#other side
#	createSide(indices, poly_bottom, surface, 0, true)
#	createSide(indices_top, poly_top, surface, 0, true)
#	createSide(indices_front, poly_front, surface, 0, true)
#	createSide(indices_rear, poly_rear, surface, 0, true)
	
	createSide(indices, poly_bottom, surface, width, true)
	# if top too low, don't make it (cabrio)
	if car_front[front_wheel_end+3].y > 0.6:
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
	
	createRear(surface, glass_surf, poly_rear)
	
	createFront(surface, glass_surf, poly_front, front_wheel_end+3)
	
	# add missing parts (hood, roof) due to exclusion below	
	# hood
	#var p = poly_front.size()-6
	var p = front_wheel_end+3+1 # where the front window ends
	var p0 = poly_front[p]
	var p1 = poly_front[p+1]
	
	createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0))
	
	#createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0), true)
	
	# roof
	# if top too low, don't make it (cabrio)
	if car_front[front_wheel_end+3].y > 0.6:
		p0 = poly_top[2]
		p1 = poly_top[3]
		createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0))
	
	#createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0), true)
	
	
	# we need to exclude the parts where the front/rear windows go (see above)
	#car.remove(car.find(poly_front[poly_front.size()-2]))
	car.remove(car.find(poly_front[front_wheel_end+3]))
	#car.remove(car.find(poly_rear[poly_rear.size()-5]))
	car.remove(car.find(poly_rear[poly_rear.size()-4]))
	
	
	indices_body = Array(Geometry.triangulate_polygon(PoolVector2Array(car)))
	
	#print("Indices: " + str(indices_body))
	linkSides(indices_body, car, surface, width)
	
	# add missing front
	p0 = poly_front[0]
	p1 = poly_front[poly_front.size()-1]
	
	createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0))
	
	#createQuadNoUV(surface, Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, width), Vector3(p1.x, p1.y, width), Vector3(p1.x, p1.y, 0), true)


# TODO: write a common function for both front and rear (90% of logic is duplicated)
func calculateFrontWindow(polygon, index):
	#var index = 2
	
	var p0 = Vector3(polygon[index+1].x, polygon[index+1].y, 0)
	var p1 = Vector3(polygon[index+1].x, polygon[index+1].y, width)
	var p2 = Vector3(polygon[index].x, polygon[index].y, 0)
	var p3 = Vector3(polygon[index].x, polygon[index].y, width)
	
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

func createFront(surface, glass_surf, polygon, index):
	var front_window_poly = calculateFrontWindow(polygon, index)	
	
	createWindow(front_window_poly, glass_surf)
	#createWindow(front_window_poly, glass_surf, true)
	
	var bottom_front = []
	bottom_front.append(Vector3(polygon[index+1].x, polygon[index+1].y, 0))
	bottom_front.append(Vector3(polygon[index+1].x, polygon[index+1].y, width))
	bottom_front.append(front_window_poly[1])
	bottom_front.append(front_window_poly[0])
	
	createQuadNoUV(surface, bottom_front[0], bottom_front[1], bottom_front[2], bottom_front[3])
	#createQuadNoUV(surface, bottom_front[0], bottom_front[1], bottom_front[2], bottom_front[3], true)
	
	var top_front = []
	top_front.append(front_window_poly[2])
	top_front.append(front_window_poly[3])
	top_front.append(Vector3(polygon[index].x, polygon[index].y, 0))
	top_front.append(Vector3(polygon[index].x, polygon[index].y, width))
	
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
	
func calculateRearWindow(polygon):
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

func createRear(surface, glass_surf, polygon):
	var rear_window_poly = calculateRearWindow(polygon)	
	
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

# functions called by in-game events		
func rain_glass():
	get_node("plane").set_surface_material(1, rain_glass_mat)		

func rain_clear():
	get_node("plane").set_surface_material(1, glass_material)

# 'pos' is local space?	
func hit_deform(pos):
	#print("Deform pos: " + str(pos))
	#var start = float(OS.get_ticks_msec())
	# setup
	var mdt = MeshDataTool.new()
	mdt.clear()
	#var st = SurfaceTool.new()
	var mesh = $"plane".get_mesh()
	#if mesh.get_surface_count() > 2:
	print("Number of surfaces: " + str(mesh.get_surface_count()))
		
	var id = 0
	if mesh.surface_find_by_name("glass") == 0:
		id = 1
	
	# copies the surface into mesh data tool
	mdt.create_from_surface(mesh, id)
	
	# Magic happens here
	var center = Vector3(0, 0, width/2)
	
	#var vtx = mdt.get_vertex(10)
	#print("Deforming vertex... " + " 10 " + str(vtx))
	var pt
	if pos.z > 0:
		pt = car_front[0]
		#print("Deform front")
	else:
		pt = car_rear[car_rear.size()-8]
		#print("Deform rear" + str(pt))
	
	var vtx = Vector3(pt.x, pt.y, 0)
	
	var done = false
	# Find all vertices that share the position, just in case
	for i in range(mdt.get_vertex_count()):
		var vt = mdt.get_vertex(i)
		if vt == vtx:
			# deform towards center
			# B-A = A->B
			var deform = (center - vt).normalized()*0.25
			vt.x += deform.x
			vt.y += deform.y
			mdt.set_vertex(i, vt)
			print("Deformed a vertex")
			done = true
	
	# don't waste time if nothing to do
	if done:
		# Remove existing surface
		#for s in range(mesh.get_surface_count()):
		mesh.surface_remove(id)
		
		# this always adds at the end
		# doesn't seem to be enough because Godot messes up material assignments, resulting in body being glass
		mdt.commit_to_surface(mesh)
		car_surface.create_from(mesh, mesh.get_surface_count()-1)
		# don't multiply surfaces!
		#mesh.surface_remove(mesh.get_surface_count()-1)
		car_surface.generate_normals()
		$"plane".mesh = car_surface.commit(mesh)
	
	# time it
	#var endtt = float(OS.get_ticks_msec())
	#print("Execution time: %.2f" % ((endtt - start)/1000))


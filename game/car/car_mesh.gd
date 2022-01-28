extends MeshInstance3D

var msh = preload("res://save_test.tres")
var car_front = []
var car_rear = []
var window_poly = []

@export var width: float = 1.0

var indices = []
var indices_top = []
var indices_front = []
var indices_rear = []


var indices_body = []
	
@export var material: StandardMaterial3D = StandardMaterial3D.new()
#export(ShaderMaterial) var glass_material = ShaderMaterial.new()
@export var glass_material: StandardMaterial3D = StandardMaterial3D.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	var car = defineCar()
	
	
	set_mesh(msh)

# exact copy of the function in procedural_car_better.gd	
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
	var id = car_rear.size()-1
	# top right, bottom right
	# inverted because the second insertion pushes the first forward
	car_rear.insert(id, window_poly[3])
	car_rear.insert(id, window_poly[2])

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
	
# 'pos' is local space?	
func hit_deform(pos):
	#print("Deform pos: " + str(pos))
	#var start = float(OS.get_ticks_msec())
	# setup
	var mdt = MeshDataTool.new()
	mdt.clear()
	#var st = SurfaceTool.new()
	var mesh = get_mesh()
	#if mesh.get_surface_count() > 2:
	#print("Number of surfaces: " + str(mesh.get_surface_count()))
		
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
			#print("Deformed a vertex")
			done = true
	
	# we need to do it even if not done, for some reason...
	# Calculate vertex normals, face-by-face.
		for j in range(mdt.get_face_count()):
			# Get the index in the vertex array.
			var a = mdt.get_face_vertex(j, 0)
			var b = mdt.get_face_vertex(j, 1)
			var c = mdt.get_face_vertex(j, 2)
			# Get vertex position using vertex index.
			var ap = mdt.get_vertex(a)
			var bp = mdt.get_vertex(b)
			var cp = mdt.get_vertex(c)
			# Calculate face normal.
			var n = (bp - cp).cross(ap - bp).normalized()
			# Add face normal to current vertex normal.
			# This will not result in perfect normals, but it will be close.
			mdt.set_vertex_normal(a, n + mdt.get_vertex_normal(a))
			mdt.set_vertex_normal(b, n + mdt.get_vertex_normal(b))
			mdt.set_vertex_normal(c, n + mdt.get_vertex_normal(c))
	
	# don't waste time if nothing to do
	if done:
		# Remove existing surface
		#mesh.surface_remove(id)

#		# this always adds at the end
		mdt.commit_to_surface(mesh)
		
		#car_surface.create_from(mesh, mesh.get_surface_count()-1)
#		#car_surface.generate_normals(true)
#		$"plane".mesh = car_surface.commit($"plane".mesh)
		#print("Number of surfaces after we're done: " + str(mesh.get_surface_count()))
		
		#for i in range($"plane".mesh.get_surface_count()):
		#	print("Mat name: " + str($"plane".mesh.surface_get_material(i).get_name()))
	
	# time it
	#var endtt = float(OS.get_ticks_msec())
	#print("Execution time: %.2f" % ((endtt - start)/1000))

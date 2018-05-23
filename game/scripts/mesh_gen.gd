extends Spatial

# class member variables go here, for example:
var TWO_PI = PI * 2
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func addRoad(material, dx, dy, dz):
	#print("Adding road " + String(dx) + String(dy) + String(dz))
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("road")
	add_child(node)
	
	addPlaneRect(0,0,0,surface, material, dx, dy, dz)	
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())

func addTerrain(material, dx, dy, dz):
	#print("Adding ground " + String(dx) + String(dy) + String(dz))
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("plane")
	add_child(node)
	
	addPlaneRect(0,0,0,surface, material, dx, dy, dz)
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
func addPlaneRect(x,y,z,surface, material, dx, dy, dz):
	#print("Adding plane... " + String(x) + " " + String(y) + " " + String(z) + " " + String(dx) + " " + String(dy) + " " + String(dz))
	
	var base = Vector3(x,y,z)
	
	var one = base + Vector3(-dx,  dy, -dz)
	var two = base + Vector3( dx,  dy, -dz)
	var three = base + Vector3( dx,  dy,  dz)
	var four = base + Vector3(-dx,  dy,  dz)
	
	addQuad(one, two, three, four, material, surface, false)
	
func addRoadCurve(material, left_one, right_one, left_two, right_two, flip_uv):
	#print("Adding curved road")
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("road_curved")
	add_child(node)
	
	addQuad(left_one, right_one, left_two, right_two, material, surface, flip_uv)
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)
	
#this one counts from 1 not 0
func addRoadCurveTest(material, one, two, three, four, five, six, parent):
	#print("Adding curved road")
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("road_curved")
	if (parent !=null):
		parent.add_child(node)
	else:
		add_child(node)
	
	addQuad(one, two, three, four, material, surface, false)
	addQuad(two, five, six, three, material, surface, true)
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)	

#clockwise order = right, left, left_ahead, right (as looking from origin)
func addQuad(one, two, three, four, material, surface, flip_uv):
	var corners = []
	#corners
	corners.push_back(one)
	corners.push_back(two)
	corners.push_back(three)
	corners.push_back(four)
	
	var uvs = []
	uvs.push_back(Vector2(0,0))
	uvs.push_back(Vector2(0,1))
	uvs.push_back(Vector2(1,1))
	uvs.push_back(Vector2(1,0))
	
	if material:
		surface.set_material(material)
	
	#Top
	surface.add_normal(Vector3(0,1,0))
	
	#First triangle
	#UV mapping 0-1-2 -- 2-3-0 for normal
	# 2-3-0 -- 0-1-2 for flipped on x axis
	#UV hint: wide line is between 0 and 3
	#First triangle
	if (flip_uv):
		surface.add_uv(uvs[2])
	else:
		surface.add_uv(uvs[0])
	surface.add_vertex(corners[0])
	if (flip_uv):
		surface.add_uv(uvs[3])
	else:
		surface.add_uv(uvs[1])
	surface.add_vertex(corners[1])
	if (flip_uv):
		surface.add_uv(uvs[0])
	else:
		surface.add_uv(uvs[2])
	surface.add_vertex(corners[2])
	#Second triangle
	if (flip_uv):
		surface.add_uv(uvs[0])
	else:
		surface.add_uv(uvs[2])
	surface.add_vertex(corners[2])
	if (flip_uv):
		surface.add_uv(uvs[1])
	else:
		surface.add_uv(uvs[3])
	surface.add_vertex(corners[3])
	if (flip_uv):
		surface.add_uv(uvs[2])
	else:
		surface.add_uv(uvs[0])
	surface.add_vertex(corners[0])

func addTri(one, two, three, material, surface):
	surface.set_material(material)
	
	var corners = []
	#corners
	corners.push_back(one)
	corners.push_back(two)
	corners.push_back(three)
	
	var uvs = []
	uvs.push_back(Vector2(0,0))
	uvs.push_back(Vector2(0,1))
	uvs.push_back(Vector2(1,1))
	
	surface.add_uv(uvs[0])
	surface.add_vertex(corners[0])
	surface.add_uv(uvs[1])
	surface.add_vertex(corners[1])
	surface.add_uv(uvs[2])
	surface.add_vertex(corners[2])
	
	
func make_circle(center, segments, radius):
	var points_arc = Vector2Array()
	var angle_from = 0
	var angle_to = 360

	for i in range(segments+1):
		var angle_point = angle_from + i*(angle_to-angle_from)/segments - 90
		var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
		points_arc.push_back( point )
	
	return points_arc
	
func addTriCustUV(one, two, three, uv_one, uv_two, uv_three, material, surface):
	surface.set_material(material)
	
	var corners = []
	#corners
	corners.push_back(one)
	corners.push_back(two)
	corners.push_back(three)
	
	var uvs = []
	uvs.push_back(uv_one)
	uvs.push_back(uv_two)
	uvs.push_back(uv_three)
	
	surface.add_uv(uvs[0])
	surface.add_vertex(corners[0])
	surface.add_uv(uvs[1])
	surface.add_vertex(corners[1])
	surface.add_uv(uvs[2])
	surface.add_vertex(corners[2])
	
func addQuadCustUV(one, two, three, four, uv_one, uv_two, uv_three, uv_four, material, surface):
	var corners = []
	#corners
	corners.push_back(one)
	corners.push_back(two)
	corners.push_back(three)
	corners.push_back(four)
	
	var uvs = []
	uvs.push_back(uv_one)
	uvs.push_back(uv_two)
	uvs.push_back(uv_three)
	uvs.push_back(uv_four)
	
	surface.set_material(material)
	

	#UV mapping 0-1-2 -- 2-3-0 for normal
	#First triangle
	surface.add_uv(uvs[0])
	surface.add_vertex(corners[0])
	surface.add_uv(uvs[1])
	surface.add_vertex(corners[1])
	surface.add_uv(uvs[2])
	surface.add_vertex(corners[2])
	
	#Second triangle
	surface.add_uv(uvs[2])
	surface.add_vertex(corners[2])
	surface.add_uv(uvs[3])
	surface.add_vertex(corners[3])
	surface.add_uv(uvs[0])
	surface.add_vertex(corners[0])
	
# textured version of a cube
func addCubeTexture(x,y,z, surface, material, dx, dy, dz):
	surface.set_material(material)
	
	#This is the central point in the base of the cube
	var base = Vector3(x, y + dy, z)
	
	##Corners of the cube
	var corners = []
	
	#Top
	corners.push_back(base + Vector3(-dx,  dy, -dz))
	corners.push_back(base + Vector3( dx,  dy, -dz))
	corners.push_back(base + Vector3( dx,  dy,  dz))
	corners.push_back(base + Vector3(-dx,  dy,  dz))
	
	#Bottom
	corners.push_back(base + Vector3(-dx, -dy, -dz))
	corners.push_back(base + Vector3( dx, -dy, -dz))
	corners.push_back(base + Vector3( dx, -dy,  dz))
	corners.push_back(base + Vector3(-dx, -dy,  dz))
	
	var uvs = []
	uvs.push_back(Vector2(0,0))
	uvs.push_back(Vector2(0,1))
	uvs.push_back(Vector2(1,1))
	uvs.push_back(Vector2(1,0))
	
	#Color red
#	surface.add_color(color)
#
	#Adding the corners in order, calculated by hand
	#Top
	addQuad(corners[0], corners[1], corners[2], corners[3], material, surface, false)
#	
	#One side
	addQuad(corners[0], corners[4], corners[5], corners[1], material, surface, false)

	#Other side
	# inverted texture
	#addQuad(corners[6], corners[2], corners[1], corners[5], material, surface, false)
	addQuad(corners[1], corners[5], corners[6], corners[2], material, surface, false)

	#Other side
	# texture flipped to the side
	#addQuad(corners[3], corners[2], corners[6], corners[7], material, surface, false)
	#addQuad(corners[7], corners[3], corners[2], corners[6], material, surface, false) #inverted
	addQuad(corners[2], corners[6], corners[7], corners[3], material, surface, false)
	
	#Other side
	# texture flipped to the side
	#addQuad(corners[0], corners[3], corners[7], corners[4], material, surface, false)
	# inverted
	#addQuad(corners[4], corners[0], corners[3], corners[7], material, surface, false)
	addQuad(corners[3], corners[7], corners[4], corners[0], material, surface, false)
	
	#Bottom
	addQuad(corners[6], corners[5], corners[4], corners[7], material, surface, false)
	#addQuad(corners[6], corners[5], corners[7], corners[4], material, surface, false)
	
func addQuadFromCube(x,y,z, surface, material, dx, dy, dz):
	surface.set_material(material)
	
	#This is the central point in the base of the cube
	var base = Vector3(x, y + dy, z)
	
	##Corners of the cube
	var corners = []
	
	#Top
	corners.push_back(base + Vector3(-dx,  dy, -dz))
	corners.push_back(base + Vector3( dx,  dy, -dz))
	corners.push_back(base + Vector3( dx,  dy,  dz))
	corners.push_back(base + Vector3(-dx,  dy,  dz))
	
	#Bottom
	corners.push_back(base + Vector3(-dx, -dy, -dz))
	corners.push_back(base + Vector3( dx, -dy, -dz))
	corners.push_back(base + Vector3( dx, -dy,  dz))
	corners.push_back(base + Vector3(-dx, -dy,  dz))
	
	var uvs = []
	uvs.push_back(Vector2(0,0))
	uvs.push_back(Vector2(0,1))
	uvs.push_back(Vector2(1,1))
	uvs.push_back(Vector2(1,0))

	#Adding the corners in order, calculated by hand
	#Top
	#if select == "top":
	#	addQuad(corners[0], corners[1], corners[2], corners[3], material, surface, false)
	#if select == "side1":
		#One side
	addQuad(corners[0], corners[4], corners[5], corners[1], material, surface, false)
	#elif select == "side2":
		#Other side
	addQuad(corners[1], corners[5], corners[6], corners[2], material, surface, false)
	#elif select == "side3":
		#Other side
	addQuad(corners[2], corners[6], corners[7], corners[3], material, surface, false)
	#elif select == "side4":
		#Other side
	addQuad(corners[3], corners[7], corners[4], corners[0], material, surface, false)
	
	#Bottom
	#addQuad(corners[6], corners[5], corners[4], corners[7], material, surface, false)
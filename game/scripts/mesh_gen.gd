extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func addTerrain(material, dx, dy, dz):
	print("Adding ground " + String(dx) + String(dy) + String(dz))
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
	print("Adding plane... " + String(x) + " " + String(y) + " " + String(z) + " " + String(dx) + " " + String(dy) + " " + String(dz))
	
	#if (material):
		#print("Adding plane... " + material.get_name())
	
	
	var base = Vector3(x,y,z)
	
	var corners = []
	#corners
	corners.push_back(base + Vector3(-dx,  dy, -dz))
	corners.push_back(base + Vector3( dx,  dy, -dz))
	corners.push_back(base + Vector3( dx,  dy,  dz))
	corners.push_back(base + Vector3(-dx,  dy,  dz))
	
	var uvs = []
	uvs.push_back(Vector2(0,0))
	uvs.push_back(Vector2(0,1))
	uvs.push_back(Vector2(1,1))
	uvs.push_back(Vector2(1,0))
	
	if (material):
		surface.set_material(material)

	##Adding the corners in order, calculated by hand
	#Top
	surface.add_normal(Vector3(0, 1, 0))
	
	#Normal order is 0-1-2 -- 2-3-0
	
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
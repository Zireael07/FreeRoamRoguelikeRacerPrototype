tool
extends "res://scripts/mesh_gen.gd"

export var wheel_thick = 0.2
export var wheel_radius = 0.25

# class member variables go here, for example:
var m = SpatialMaterial.new()

export(Material) var material = SpatialMaterial.new()

func _ready():
	var half_thick = wheel_thick/2
	var circle = make_circle(Vector2(), 16, wheel_radius)
	
	#for point in circle:
	#	draw_debug_point(point, Color(1,0,0))
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("plane")
	add_child(node)
	
	#addTri(Vector3(), Vector3(circle[0].x, 0, circle[0].y), Vector3(circle[1].x, 0, circle[1].y), material, surface)
	#default
	#var cust_uv = [Vector2(0, 0), Vector2(0,1), Vector2(1,1)]
	# lines on the inner edges
	#var cust_uv = [Vector2(0,0), Vector2(0,1), Vector2(1,0)]
	# left inner edge lined
	#var cust_uv = [Vector2(0,0), Vector2(0.5, 0.5), Vector2(0,1)]
	# right inner edge lined
	#var cust_uv = [Vector2(0,0), Vector2(0,1), Vector2(0.5, 0.5)]
	# outer edge lined
	var cust_uv = [Vector2(0.5, 0.5),Vector2(0,1), Vector2(1,1)]
	
	#addTriCustUV(Vector3(), Vector3(circle[0].x, 0, circle[0].y), Vector3(circle[1].x, 0, circle[1].y), cust_uv[0], cust_uv[1], cust_uv[2], material, surface)
	
	for i in range(0, circle.size()-1):	
		#addTri(Vector3(), Vector3(circle[i].x, 0, circle[i].y), Vector3(circle[i+1].x, 0, circle[i+1].y), material, surface)
		# one flat
		addTriCustUV(Vector3(0, -half_thick, 0), Vector3(circle[i].x, -half_thick, circle[i].y), Vector3(circle[i+1].x, -half_thick, circle[i+1].y), cust_uv[0], cust_uv[1], cust_uv[2], material, surface)
		# see from other side
		addTriCustUV(Vector3(circle[i+1].x, -half_thick, circle[i+1].y), Vector3(circle[i].x, -half_thick, circle[i].y), Vector3(0, -half_thick, 0), cust_uv[2], cust_uv[1], cust_uv[0], material, surface)
		# other flat
		addTriCustUV(Vector3(0, half_thick, 0), Vector3(circle[i].x, half_thick, circle[i].y), Vector3(circle[i+1].x, half_thick, circle[i+1].y), cust_uv[0], cust_uv[1], cust_uv[2], material, surface)
		# see from other side
		addTriCustUV(Vector3(circle[i+1].x, half_thick, circle[i+1].y), Vector3(circle[i].x, half_thick, circle[i].y), Vector3(0, half_thick,0), cust_uv[2], cust_uv[1], cust_uv[0], material, surface)
		
	#addTri(Vector3(circle[1].x, half_thick, circle[1].y), Vector3(circle[0].x, half_thick, circle[0].y), Vector3(0, half_thick,0), material, surface)
	
	var rim_uv = Vector2(1,1)
	
	for i in range(0, circle.size()-1):
		var x_low = circle[i].x
		var y_low = circle[i].y
		var x_high = circle[i+1].x
		var y_high = circle[i+1].y
		
		#from the top
		addQuadCustUV(Vector3(x_low, -half_thick, y_low), Vector3(x_low, half_thick, y_low), Vector3(x_high, half_thick, y_high), Vector3(x_high, -half_thick, y_high), rim_uv, rim_uv, rim_uv, rim_uv, material, surface)
		#from bottom
		addQuadCustUV(Vector3(x_high, -half_thick, y_high), Vector3(x_high, half_thick, y_high), Vector3(x_low, half_thick, y_low), Vector3(x_low, -half_thick, y_low), rim_uv, rim_uv, rim_uv, rim_uv, material, surface)
	
	surface.generate_normals()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())

#func draw_debug_point(loc, color):
#	addTestColor(m, color, null, loc.x, 0, loc.y, 0.05,0.05,0.05)

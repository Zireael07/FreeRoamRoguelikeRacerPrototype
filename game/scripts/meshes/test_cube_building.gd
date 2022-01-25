@tool
extends "mesh_gen.gd"

# class member variables go here, for example:
@export var height: int = 1
@export var width: int = 1
@export var thick: int = 1
# var b = "textvar"

func _ready():
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	#Create a node building that will hold the mesh
	var node = MeshInstance3D.new()
	node.set_name("building")
	add_child(node)
	
	
	var mat = preload("res://assets/building_shader_matl.tres")
	#var mat = StandardMaterial3D.new()
	
	addCubeTexture(0,0,0, surface, mat, width,height,thick)
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())
	
	
	# Called when the node is added to the scene for the first time.
	# Initialization here
	#pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

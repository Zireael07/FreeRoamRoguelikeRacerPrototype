@tool

extends "mesh_gen.gd"

# class member variables go here, for example:
@export var snow = false
@export var snowmaterial: StandardMaterial3D = null
@export var groundmaterial: StandardMaterial3D = null

var terrainmaterial = null

func _ready():
	if snow:
		terrainmaterial = snowmaterial
	else:
		terrainmaterial = groundmaterial
	
	
	if (terrainmaterial):
		addTerrain(terrainmaterial, 500, -0.05, 500)
	else:
		print("No materials")
	
	# having several collision shapes seems to have a problem where randomly one of them won't register
	#setup_collision(0,0)
	#setup_collision(400,0)
	#setup_collision(0,400)
	#setup_collision(400,0)

func setup_collision(x,z):
	var shape = BoxShape3D.new()
	shape.set_extents(Vector3(200,0.05,200))
	var coll = CollisionShape3D.new()
	coll.shape = shape
	coll.set_translation(Vector3(x, 0, z))
	get_node(^"StaticBody3D").add_child(coll)

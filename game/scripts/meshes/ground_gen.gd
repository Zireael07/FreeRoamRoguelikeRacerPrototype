tool

extends "mesh_gen.gd"

# class member variables go here, for example:
export var snow = false
export(SpatialMaterial) var snowmaterial = null
export(SpatialMaterial) var groundmaterial = null

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
	var shape = BoxShape.new()
	shape.set_extents(Vector3(200,0.05,200))
	var coll = CollisionShape.new()
	coll.shape = shape
	coll.set_translation(Vector3(x, 0, z))
	get_node("StaticBody").add_child(coll)

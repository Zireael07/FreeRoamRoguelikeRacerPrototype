tool

extends "mesh_gen.gd"

# class member variables go here, for example:
export(SpatialMaterial) var terrainmaterial = null

func _ready():
	if (terrainmaterial):
		addTerrain(terrainmaterial, 500, -0.05, 500)
	else:
		print("No materials")
	
	setup_collision(0,0)
	setup_collision(400,0)
	setup_collision(0,400)
	setup_collision(400,0)
	
	pass

func setup_collision(x,z):
	var shape = BoxShape.new()
	shape.set_extents(Vector3(200,0.05,200))
	var coll = CollisionShape.new()
	coll.shape = shape
	coll.set_translation(Vector3(x, 0, z))
	get_node("StaticBody").add_child(coll)

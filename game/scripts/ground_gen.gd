tool

extends "mesh_gen.gd"

# class member variables go here, for example:
export(FixedMaterial) var terrainmaterial = null

func _ready():
	if (terrainmaterial):
		addTerrain(terrainmaterial, 500, -0.1, 500)
	else:
		print("No materials")
	
	pass

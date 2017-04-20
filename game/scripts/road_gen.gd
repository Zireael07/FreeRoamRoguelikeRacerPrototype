tool

extends "mesh_gen.gd"

# class member variables go here, for example:
export(FixedMaterial)    var material    = null

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	if (!material):
		print("No material")
	else:
		addRoad(material, 3, 0, 3)
		print("Adding road")
	pass

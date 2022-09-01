extends CSGCombiner3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	_update_shape()
	var msh = get_meshes()
	print(msh)
	
	# yay GD 3
	#msh[1].create_convex_collision()
	
	ResourceSaver.save(msh[1], "res://csg_dealer2.tres")
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

tool
extends "res://2d tests/poisson2D.gd"

# class member variables go here, for example:
var mult = 3

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	# poisson stuff
	for ix in range(nx):
		for iy in range(ny):
			coords_list.append([ix, iy])
	
	for coords in coords_list:
		# we can't use straightforward coords as key :(
		var key = Vector2(coords[0], coords[1])
		# we can't store null as value, so...
		cells[key] = -1

		
	run()

	# 3d map
	#print(samples)
	
	
	map()
	
	#pass

func map():
	for p in samples:
		debug_cube(Vector3(p[0]*mult, 2, p[1]*mult))



#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
func debug_cube(loc):
	var mesh = CubeMesh.new()
	mesh.set_size(Vector3(1,1,1))
	var node = MeshInstance.new()
	node.set_mesh(mesh)
	add_child(node)
	node.set_translation(loc)
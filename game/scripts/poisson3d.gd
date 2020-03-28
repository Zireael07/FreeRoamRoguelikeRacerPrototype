tool
extends "res://2d tests/poisson2DNode.gd"

# class member variables go here, for example:
var mult = 2
#export var seed3 = 104686263 setget set_seed3
var seed3 = 10000001 #3046862638

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	# poisson stuff
	set_seed3(seed3)
	#seede = seed3
	#set_seed(seed3)
#	for ix in range(nx):
#		for iy in range(ny):
#			coords_list.append([ix, iy])
#
#	for coords in coords_list:
#		# we can't use straightforward coords as key :(
#		var key = Vector2(coords[0], coords[1])
#		# we can't store null as value, so...
#		cells[key] = -1
#
#
#	run()

	# 3d map
	#print(samples)
	
	# debug
	#map()
	
	#pass

# because we can't use the extended?
func set_seed3(value):
	#print("Seed3 value is " + str(value))
	# if not set_get we don't need this
	#if !Engine.editor_hint:
	#yield(self, 'tree_entered')
	
	for ix in range(nx):
		for iy in range(ny):
			coords_list.append([ix, iy])
	
	for coords in coords_list:
		# we can't use straightforward coords as key :(
		var key = Vector2(coords[0], coords[1])
		# we can't store null as value, so...
		cells[key] = -1
	
	seed(value)
	#rand_seed(value)
	run()
	
	# convex (outline)
	var vec2 = []
	for s in samples:
		vec2.append(Vector2(s[0], s[1]))
		
	var conv = Geometry.convex_hull_2d(vec2)
	print("Convex hull: " + str(conv))
	for i in range(0, conv.size()-1):
		var ed = [conv[i], conv[i+1]]
		out_edges.append(ed)
	
	#print("Seed3 " + str(seede))



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

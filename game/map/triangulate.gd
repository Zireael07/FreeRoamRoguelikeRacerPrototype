@tool
extends "res://2d tests/Delaunay2D.gd"
#extends Node3D

# class member variables go here, for example:
var tris = []

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here

	# randomize
	#randomize()
	#get_child(0).set_seed(randi())
	get_child(0).set_seed(10000001)


	setup()
	
	#print(points)
	tris = super.TriangulatePolygon(points)
	print(tris)
	
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


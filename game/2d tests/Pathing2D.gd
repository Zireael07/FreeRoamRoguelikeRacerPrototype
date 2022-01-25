@tool
extends Node2D

# class member variables go here, for example:
var Intersections_AS
var path

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	# in 3d procedural map, this is done as part of the distance map creation
	Intersections_AS = AStar.new()
	
	# astar wants Vector3
	# define points
	Intersections_AS.add_point(0, _posto3d(get_child(0).get_child(0).get_position()))
	Intersections_AS.add_point(1, _posto3d(get_child(0).get_child(1).get_position()))
	Intersections_AS.add_point(2, _posto3d(get_child(0).get_child(2).get_position()))
	
	# NOTE: should be done along with the intersection connecting itself
	Intersections_AS.connect_points(0,1)
	Intersections_AS.connect_points(0,2)
	Intersections_AS.connect_points(1,2)
	
	# test
	print("Intersections path from 0 to 2: " + str(Intersections_AS.get_point_path(0,2)))
	
	# test
	# 4 intersections; the line we're looking for is the 2nd line
	print("Sub path 0: " + str(get_child(0).get_child(3+2).AS.get_point_path(0,2)))
	
	
	
	
	#pass

func _posto3d(pos):
	return Vector3(pos.x, 0, pos.y)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

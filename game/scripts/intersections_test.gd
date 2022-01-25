@tool
#extends Node
extends "../map/connect_intersections.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	# just the intersection selection
	connect_intersections(0,1)
	connect_intersections(0,2)

	connect_intersections(2,3)	
	connect_intersections(0,4)
	
	
	#pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

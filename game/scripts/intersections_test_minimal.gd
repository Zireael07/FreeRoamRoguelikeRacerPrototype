@tool
#extends Node
extends "../map/connect_intersections.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	# need to do it explicitly in Godot 4 for some reason
	super._ready()

	# just the intersection selection
	connect_intersections(0,1, true)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

tool
extends Node2D

# class member variables go here, for example:
# points
var point_one = Vector2(0,10)
var point_two = Vector2(12,0)
var point_three = Vector2(0,-10)

var open_exits = [point_one, point_two, point_three]

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _draw():
	draw_line(Vector2(0,0), point_one, Color(1,0,0))
	draw_line(Vector2(0,0), point_two, Color(1,0,0))
	draw_line(Vector2(0,0), point_three, Color(1,0,0))


#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

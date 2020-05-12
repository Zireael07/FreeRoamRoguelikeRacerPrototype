tool

extends Node2D

# class member variables go here, for example:
var first = Vector2(0,0)
var length = 50
var last = Vector2(0,0)
#var pos_start = Vector2(0,0)
#var pos_end = Vector2(0,0)

var start_vector = Vector2(0,0)
var end_vector = Vector2(0,0)
var start_ref = Vector2(0,0)
var end_ref = Vector2(0,0)

func _ready():
	last = Vector2(first.x+length, first.y)
	
	var pos_start = Vector2(first.x+length/4, first.y)
	var pos_end = Vector2(last.x-length/4, last.y)
	
	# normalizing the vectors solves problems with angle_to()
	start_vector = Vector2(pos_start - first).normalized()*10
	#B-A = from a to b
	end_vector = Vector2(last - pos_end).normalized()*10
	#print("[Straight] Start vector: " + str(start_vector) + " end vector " + str(end_vector))
	
	start_ref = first+start_vector
	end_ref = last+end_vector
	
	# Called every time the node is added to the scene.
	# Initialization here
	#pass
	
func _get_item_rect():
	return Rect2(Vector2(-1,-1), Vector2(length, 5))

func _draw():
	draw_line(first, last, Color(0,0,0), 4)
	
	draw_line(first, start_ref, Color(0,1,0))
	draw_line(last, end_ref, Color(1,0,0))
	
	# debugging
	draw_circle(first, 1, Color(0,1,0))
	draw_circle(last, 1, Color(1,0,0))

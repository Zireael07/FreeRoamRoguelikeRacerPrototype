tool
extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func vec2tocamcenter(vec2):
	return Vector2(vec2.x + 250/2, vec2.y + 250/2)


func _draw():
	draw_line(Vector2(55,30), Vector2(55, -80), Color(1,0,0), 3.0)
	
	# test
	#draw_line(vec2tocamcenter(Vector2(0,0)), vec2tocamcenter(Vector2(0,20)), Color(1,0,0), 3.0)
	#draw_line(vec2tocamcenter(Vector2(-20,0)), vec2tocamcenter(Vector2(40,0)), Color(1,0,0), 3.0)
	
	#draw_line(vec2tocamcenter(Vector2(55, 30)), vec2tocamcenter(Vector2(55, -80)), Color(1,0,0), 3.0)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

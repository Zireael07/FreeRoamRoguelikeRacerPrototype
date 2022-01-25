@tool
extends Node2D

# class member variables go here, for example:
#export(PackedVector2Array) var points = []
var points = PackedVector2Array()

func _ready():
	#points = [Vector2(-52, 30), Vector2(-150, 50), Vector2(-50, 100)]
	
	#test
	#var raceline = [Vector3(-52, 0, 141), Vector3(-48, 0, 234), Vector3(-46, 0, 240), Vector3(-41, 0, 244), Vector3(-36,0, 245), Vector3(49,0, 248), Vector3(50,0,248)]
	#points = vec3s_convert(raceline)
	pass

#func vec2tocamcenter(vec2):
#	return Vector2(vec2.x + 250/2, vec2.y + 250/2)

func vec3s_convert(vec3s):
	points = []
	for v in vec3s:
		points.append(vec3tovec2(v))
		
	return points

func vec3tovec2(vec3):
	return Vector2(-vec3.x, -vec3.z)

func _draw():
	if points.size() > 0:
		#print("Should draw" + str(points))
		for i in range(points.size()-1):
			draw_line(points[i], points[i+1], Color(1,0,0), 3.0)
			
			
	#draw_line(Vector2(55,30), Vector2(55, -80), Color(1,0,0), 3.0)
	
	# test
	#draw_line(vec2tocamcenter(Vector2(0,0)), vec2tocamcenter(Vector2(0,20)), Color(1,0,0), 3.0)
	#draw_line(vec2tocamcenter(Vector2(-20,0)), vec2tocamcenter(Vector2(40,0)), Color(1,0,0), 3.0)
	
	#draw_line(vec2tocamcenter(Vector2(55, 30)), vec2tocamcenter(Vector2(55, -80)), Color(1,0,0), 3.0)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

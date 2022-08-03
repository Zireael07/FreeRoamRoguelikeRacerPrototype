extends Control

var data = [ [Vector3(0,0,0) ] ] # dummy values
var rays = []
# Called when the node enters the scene tree for the first time.
func _ready():
	data = [ [Vector3(0,0,0) ]
	pass # Replace with function body.

func _draw():
	for p in data:
		# 1m=20px scale
		draw_rect(Rect2(Vector2(p[0].x*20, p[0].z*20), Vector2(20, 20)), Color(1,0,0))
	for i in range(rays.size()):
		var r = rays[i]
		var clr = Color(0,0,1)
		draw_line(Vector2(0,0), Vector2(r.x*20, r.z*20), clr)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update() #redraw
	pass

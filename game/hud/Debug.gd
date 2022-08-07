extends Control

var data = [ [Vector3(0,0,0), Vector2(0,0), 0 ] ] # dummy values
var rays = []

var danger = []
var interest = []
var choice = Vector3(0,0,0)
# Called when the node enters the scene tree for the first time.
func _ready():
	data = [ [Vector3(0,0,0), Vector2(0,0), 0] ]
	pass # Replace with function body.

func _draw():
	for p in data:
		# 1m=20px scale
		draw_rect(Rect2(Vector2(p[0].x*20, p[0].z*20), Vector2(20, 20)), Color(1,0,0))
		# test grid cell?
		#draw_rect(Rect2(Vector2(p[1].x*20, p[1].y*20), Vector2(20, 20)), Color(1,1,0))

	for i in range(rays.size()):
		var r = rays[i]
		var clr = Color(0,0,1)
		# draw red direction if it's being blocked by something
		for p in data:
			if p[2] == i:
				clr = Color(1,0,0)
		draw_line(Vector2(0,0), Vector2(r.x*20, r.z*20), clr)

		# draw interest/danger
		draw_line(Vector2(0,0), Vector2(r.x, r.z).normalized()*interest[i]*40, Color(0,1,0), 2.0)
		if danger[i] > 0.0:
			draw_line(Vector2(0,0), Vector2(r.x, r.z).normalized()*danger[i]*40, Color(1,0,0), 2.0)
	
	# chosen direction
	draw_line(Vector2(0,0), Vector2(choice.x*40, choice.z*40), Color(0,0,0), 4.0)	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update() #redraw
	pass

tool
extends Polygon2D

# Declare member variables here. Examples:
var font

# Called when the node enters the scene tree for the first time.
func _ready():
	
#	# text
#	var label = Label.new()
#	font = label.get_font("")
#	label.free()
#
	
	var trueno = [Vector2(-0.764126, 0.07102), Vector2(-0.587397, 0.011519), Vector2(-0.456753, -0.004075), Vector2(-0.338316, 0.180084), Vector2(-0.20599, 0.293982), Vector2(-0.083261, 0.209353), Vector2(-0.03591, 0.106849), 
	Vector2(-0.036215, 0.007574), Vector2(1.15943, 0.007378), Vector2(1.1816, 0.145438), Vector2(1.28406, 0.247247), Vector2(1.38462, 0.288478), 
	Vector2(1.56198, 0.060509), Vector2(1.83474, 0.060503), Vector2(1.88706, 0.297294), Vector2(1.81217, 0.563924), Vector2(1.59168, 0.581192), Vector2(1.47597, 0.635872), Vector2(1.19123, 0.778995), Vector2(0.419381, 0.784911), Vector2(-0.04922, 0.452933), Vector2(-0.338839, 0.437128), Vector2(-0.743482, 0.322674)]
	
	for i in range(trueno.size()):
		# scale
		var tmp = trueno[i]*1000
		trueno[i] = tmp
	
	
	set_polygon(trueno)
	
	# redraw
	#update()
	
	
	#pass # Replace with function body.

#func _draw():
#	for i in get_polygon().size():
#		draw_string(font, get_polygon()[i], str(i)) 


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

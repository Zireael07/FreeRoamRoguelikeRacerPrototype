@tool
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
	var trueno = []
	# bottom left, top left, top right, bottom right
	var trueno_side_window = [Vector2(0.102906, 0.489506), Vector2(0.45022, 0.745425), Vector2(1.13577, 0.741807), Vector2(1.19646, 0.511102)]
	
	
	if get_name() == "Polygon2D":	
		trueno = [Vector2(-0.764126, 0.07102), Vector2(-0.587397, 0.011519), Vector2(-0.456753, -0.004075), Vector2(-0.338316, 0.180084), Vector2(-0.20599, 0.293982), Vector2(-0.083261, 0.209353), Vector2(-0.03591, 0.106849), 
	Vector2(-0.036215, 0.007574), Vector2(1.15943, 0.007378), Vector2(1.1816, 0.145438), Vector2(1.28406, 0.247247), Vector2(1.38462, 0.288478), 
	Vector2(1.56198, 0.060509), Vector2(1.83474, 0.060503), Vector2(1.88706, 0.297294), Vector2(1.81217, 0.563924), Vector2(1.59168, 0.581192), Vector2(1.47597, 0.635872), Vector2(1.19123, 0.778995), Vector2(0.419381, 0.784911), Vector2(-0.04922, 0.452933), Vector2(-0.338839, 0.437128), Vector2(-0.743482, 0.322674)]
	else:
		var trueno_rear = [Vector2(1.15943, 0.007378), Vector2(1.1816, 0.145438), Vector2(1.28406, 0.247247), Vector2(1.38462, 0.288478),
	Vector2(1.56198, 0.060509), Vector2(1.83474, 0.060503), Vector2(1.88706, 0.297294), Vector2(1.81217, 0.563924), Vector2(1.59168, 0.581192),
	Vector2(1.47597, 0.635872), Vector2(1.19123, 0.778995)
	]

		# missing wheel well points
		var val3 = (trueno_rear[4]+trueno_rear[3])/2 # midpoint
		trueno_rear.insert(4, val3)
		var val4 = (trueno_rear[5]+trueno_rear[4])/2 # midpoint
		trueno_rear.insert(5, val4)
		
		# split final edge to avoid problems polygonizing when windows are involved
		var tmp = (trueno_rear[0]+trueno_rear[trueno_rear.size()-1])/2 # midpoint
		trueno_rear.append(tmp)
		
		# windows
		# because the final point is the midpoint
		var i = trueno_rear.size()-1
		# top right, bottom right
		# inverted because the second insertion pushes the first forward
		trueno_rear.insert(i, trueno_side_window[3])
		trueno_rear.insert(i, trueno_side_window[2])
		
		
		trueno = trueno_rear
	
	
	for i in range(trueno.size()):
		# scale
		var tmp = trueno[i]*1000
		trueno[i] = tmp
	
	
	set_polygon(trueno)
	
	# redraw
	#queue_redraw()
	
	
	#pass # Replace with function body.

func trueno_front(trueno_side_window):
	var trueno = [Vector2(-0.764126, 0.07102), Vector2(-0.456753, -0.004075), Vector2(-0.338316, 0.180084), Vector2(-0.20599, 0.293982), 
	Vector2(-0.083261, 0.209353), Vector2(-0.036215, 0.007574),
	# top part
	Vector2(0.419381, 0.784911), Vector2(-0.04922, 0.452933), Vector2(-0.743482, 0.322674)
	]

	# missing points for wheel wells trueno
	var val1 = (trueno[2]+trueno[1])/2 # midpoint
	var val2 = (trueno[5]+trueno[4])/2 # midpoint
	var add = [[2, val1], [6, val2]] #need to remember that the first point is inserted already, so the index is increased by 1 

	for i in range(add.size()):
		var p = add[i]
		trueno.insert(p[0], p[1])

	# windows
	
	
	var front_wheel_end = 7
	# inverted because the second insertion pushes the first forward
	trueno.insert(front_wheel_end+1, trueno_side_window[1])
	trueno.insert(front_wheel_end+1, trueno_side_window[0]) 


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

extends Control

var interest = []
var danger = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# the rect is 40 px tall, so we start at 40 px
# the value of 1 is represented by the line all the way to the top (to 0 px)
func calc_line_end(data_point):
	var lrp = range_lerp(clamp(data_point, 0,1), 0, 1, 40.0, 1.0) 
	#print("Line end for ", data_point, ": ", lrp)
	return lrp

func update_vis():
	# assume interest and danger are of equal size
	for i in interest.size()-1:
		get_child(i).update_data(calc_line_end(interest[i]), calc_line_end(danger[i]))


#func _draw():
#	draw_rect()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

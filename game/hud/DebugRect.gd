extends ColorRect

var data = [40,40]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func update_data(interest, danger):
	#print("data: ", interest, ", ",  danger)
	data = [interest, danger]
	# force redraw
	queue_redraw()

#  data[0] is interest, data[1] is danger
func _draw():
	draw_line(Vector2(15,40), Vector2(15,data[0]),Color(0,1,0),4) # green
	draw_line(Vector2(5,40), Vector2(5,data[1]), Color(1,0,0), 4) # red



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

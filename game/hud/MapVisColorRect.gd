extends ColorRect

var rects = []
var line

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

#func _fixed_process():
#	queue_redraw() #redraw

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#count += 1
	#print("Count: ", count, " d: ", delta)
	#print("R:", rects)
	#queue_redraw()
	pass
	
func _draw():
	for p in rects:
		draw_rect(Rect2(Vector2(p), Vector2(10,10)), Color(1,1,1))	

	if line != null:
		draw_line(rects[line[0]], rects[line[1]], Color(1,1,1))

func redraw():
	#print("Hello from vis! ", rects)
	#get_parent().get_node("Label").set_text(var_to_str(rects)) # test
	queue_redraw() # redraw

func prepare_labels(num):
	for i in range(num):
		var l = Label.new()
		l.set_name(var_to_str(i))
		add_child(l)
		l.hide()
	
#func prepare_icons(num):
#	for i in range(num):
#		var r = $ColorRect.duplicate()
#		r.position = Vector2(250,250) # test
#		add_child(r)
		#r.hide()

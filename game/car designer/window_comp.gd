@tool
extends Polygon2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	# bottom left, top left, top right, bottom right
	#var trueno_side_window = [Vector2(0.102906, 0.489506), Vector2(0.45022, 0.745425), Vector2(1.13577, 0.741807), Vector2(1.19646, 0.511102)]
	
	# CCW in order to be able to see in editor
	var trueno_side_window = [Vector2(0.102906, 0.489506), Vector2(1.19646, 0.511102), Vector2(1.13577, 0.741807), Vector2(0.45022, 0.745425)]
	
	for i in range(trueno_side_window.size()):
		# scale
		var tmp = trueno_side_window[i]*1000
		trueno_side_window[i] = tmp
	
	set_polygon(trueno_side_window)
	#pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

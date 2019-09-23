tool
extends Polygon2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# output
	var out = []
	for i in range(get_polygon().size()):
		out.append(Vector2(get_polygon()[i].x/1000, (get_polygon()[i].y-601.5)/1000))
		
	print(out)

	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

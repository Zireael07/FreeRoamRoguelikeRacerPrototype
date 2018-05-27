tool
extends Polygon2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _draw():
	if get_polygon() != null:
		for p in get_polygon():
			draw_circle(p, 3.0, Color(get_color().r, get_color().g, get_color().b, 1)) #Color(1,0,0))


#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

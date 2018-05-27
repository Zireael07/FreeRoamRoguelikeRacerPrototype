tool
extends Node

# class member variables go here, for example:
var pts = []
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _draw():
	if pts.size() > 0:
		for p in pts:
			draw_circle(p, 3.0, Color(1,0,0))

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

extends ViewportContainer


# Declare member variables here. Examples:
var cam = null


# Called when the node enters the scene tree for the first time.
func _ready():
	cam = get_node("Viewport/Camera2D")



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# zoom in
func _on_ButtonPlus_pressed():
	# any closer and it's too blurry
	if cam.zoom.x > 0.75:
		cam.zoom.x -= 0.25
		cam.zoom.y -= 0.25

# zoom out
func _on_ButtonMinus_pressed():
	cam.zoom.x += 0.25
	cam.zoom.y += 0.25




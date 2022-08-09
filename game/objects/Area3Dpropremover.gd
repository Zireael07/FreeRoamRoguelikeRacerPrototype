extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_area_3d_body_entered(body):
	if body is StaticBody3D:
		# exclude planes
		if body.get_name() == "plane_col":
			return
		if body.get_parent().get_parent().get_name() == "Navigation":
			return
		# ignore ourselves
		if body.get_parent() == get_parent():
			return
		
		# if a prop overlaps intersection...
		print("Static body " + String(body.get_parent().get_parent().get_name()) + " overlaps us!!!")
		# yeet it
		body.get_parent().queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

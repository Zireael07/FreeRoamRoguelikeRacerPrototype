extends Spatial

# class member variables go here, for example:
var target_orig
var origin
var target
var delta_mv

func _ready():
	origin = get_global_transform().origin
	target_orig = get_parent().get_global_transform().origin
	# This detaches the camera transform from the parent spatial node
	set_as_toplevel(true)
	#set_physics_process(true)
	set_process(true)
	
	# Called every time the node is added to the scene.
	# Initialization here
	pass
	
#func _physics_process(dt):
func _process(delta):
	target = get_parent().get_global_transform().origin
	#var pos = get_global_transform().origin
	#var up = Vector3(0, 1, 0)
	
	delta_mv = target - target_orig
		
	#move up and rotate to look down
	set_translation(origin+delta_mv)
	
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

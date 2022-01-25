extends Node3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.

func setup_ik():
	#var tg_path = get_node(^"Armature/Node3D/Position3D_left").get_path()
	#var tg_path2 = get_node(^"Armature/Node3D/Position3D_right").get_path()
	#get_node(^"Armature/SkeletonIK_left").set_target_node(tg_path)
	#get_node(^"Armature/SkeletonIK_right").set_target_node(tg_path2)
	

	
	#get_node(^"Armature/SkeletonIK_left").set_target_transform(get_transform().xform_inv(tg_tra))
	
	get_node(^"Armature/SkeletonIK_left").start()
	#print(str(get_node(^"Armature/SkeletonIK_left").get_target_transform()))
	get_node(^"Armature/SkeletonIK_right").start()
	#print(str(get_node(^"Armature/SkeletonIK_right").get_target_transform()))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

tool

extends Position3D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	pass

func place_road():
#	if get_tree().is_editor_hint():
#		print("Editor mode")
#	else:
		var road = get_node("Road")
		
		if (road != null):
			#print("We have a road")
			
			#var end = road.last
			#print("End is " + String(end))
			#var locate = Vector3(end.x, 0, end.z)
			var begin = road.start_point

			# rotate to point in the correct z direction
			var locate = Vector3(begin.x, 0, begin.z)
			road.set_rotation_degrees(Vector3(0, 180, 0))
			
			


			road.set_translation(locate)

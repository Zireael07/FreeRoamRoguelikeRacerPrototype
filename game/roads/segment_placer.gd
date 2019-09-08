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
			
			var begin = road.start_point
			Logger.road_print(road.get_parent().get_parent().get_name() + " beginning is " + String(begin))
			
			var locate = Vector3(-begin.x, 0, -begin.z)
			
#			var trans = road.get_translation()
#			#place ourselves at 0,0 temporarily
#			road.translate(-trans)
#			road.translate(locate)

			road.set_translation(locate)
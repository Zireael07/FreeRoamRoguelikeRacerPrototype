tool

extends Node2D

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
		var road = get_child(0)
		
		if (road != null):
			#print("We have a road")
			
			var begin = road.first
			#print(road.get_parent().get_parent().get_name() + " beginning is " + String(begin))
			
			var locate = begin
			road.set_rotation_degrees(180)

			road.set_position(locate)

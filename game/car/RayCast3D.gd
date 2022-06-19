extends RayCast3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_collider_hit():
	#print("Getting collider for " + get_name())
	if (is_colliding() and (get_collider() != null)):
		#print("Get collider" + get_collider().get_name())
		return get_collider()
	else:
		return null

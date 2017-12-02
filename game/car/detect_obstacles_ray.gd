extends RayCast

# class member variables go here, for example:
var loc
var hit

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	set_physics_process(true)
	
	pass

func get_collider_hit():
	#print("Getting collider for " + get_name())
	if (is_colliding() and (get_collider() != null)):
		#print("Get collider" + get_collider().get_name())
		return get_collider()
	else:
		return null

func _physics_process(delta):
	if (is_colliding() and (get_collider() != null)):
		hit = true
	else:
		hit = false
	
	
	loc = self.get_cast_to() 
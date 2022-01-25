extends GPUParticles3D

# Declare member variables here. Examples:

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# remove old particles
func _on_Timer_timeout():
	#print("Time out particles")
	queue_free()
	
	
	#pass # Replace with function body.

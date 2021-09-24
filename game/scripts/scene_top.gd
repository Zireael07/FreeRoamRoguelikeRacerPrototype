extends Navigation


# Declare member variables here. Examples:
var vehicles = {"car": true}
var discovered_roads = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# new in 3.4 - room conversion
	get_node("RoomManager").rooms_convert()
	print("Rooms converted!")
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

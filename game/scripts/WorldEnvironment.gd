# it's one of the first nodes in tree, so it has startup stuff for gameplay
extends WorldEnvironment

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	# refer to logger.gd, constants
	# 4 = ERROR 5 = ROAD_GEN 6 = MAPGEN
	Logger.set_level(4)
	#pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

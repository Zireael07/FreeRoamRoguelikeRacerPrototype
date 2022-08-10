# based on https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/
extends Node

signal load_ended
signal mapgen_done

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mapgen_done", mapgendone)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func mapgendone():
	print("[MAPGEN] Finished!")

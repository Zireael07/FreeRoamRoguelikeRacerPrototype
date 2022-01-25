extends Node3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# remove old marks
func _on_Timer_timeout():
	#print("Time out particles")
	queue_free()

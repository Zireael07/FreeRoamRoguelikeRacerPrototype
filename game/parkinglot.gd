@tool
extends Node3D

@export var rows = 2
@export var spots = 2 

# Called when the node enters the scene tree for the first time.
func _ready():
	# these are based on the texture (parkinglot.png)
	get_node("MeshInstance3D").get_mesh().size = spots
	get_node("MeshInstance3D").get_mesh().sections = rows
	
	# auto-size material
	get_node("MeshInstance3D").get_mesh().get_material().uv1_scale = Vector3(spots-1, rows, 1)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

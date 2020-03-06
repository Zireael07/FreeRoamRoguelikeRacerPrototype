extends Area

# Declare member variables here. Examples:
var player_script 

# Called when the node enters the scene tree for the first time.
func _ready():
	player_script = load("res://car/vehicle_player.gd")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Area_body_entered(body):
	if body is VehicleBody:
		if body is player_script:
			pass
			#print("Intersection: " + get_parent().get_name())


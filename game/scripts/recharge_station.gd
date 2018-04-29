extends Spatial

# class member variables go here, for example:
var player
var player_script
var charging = false

func _ready():
	player_script = load("res://car/vehicle_player.gd")


func _on_Area_body_entered(body):
	if body is VehicleBody:
		if body is player_script:
			print("Charging area entered by the player")
			player = body
			charging = true

func _process(delta):
	if player != null and charging:
		if player.battery < 100:
			player.battery += 1

func _on_Area_body_exited(body):
	if body is VehicleBody:
		if body is player_script:
			print("Charging area exited by the player")
			player = body
			charging = false
	#pass # replace with function body

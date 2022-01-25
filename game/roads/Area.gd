extends Area3D

# Declare member variables here. Examples:
var player_script 

# Called when the node enters the scene tree for the first time.
func _ready():
	#player_script = load("res://car/vehiclebody/vehicle_player.gd")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Area_body_entered(body):
#	if body is VehicleBody3D:
#		if body is player_script:
#			pass
			#print("Intersection: " + get_parent().get_name())
	
	if body is StaticBody3D:
		# exclude planes
		if body.get_name() == "plane_col":
			return
		if body.get_parent().get_parent().get_name() == "Navigation":
			return
		
		# if a prop overlaps intersection...
		print("Static body " + body.get_parent().get_parent().get_name() + " overlaps intersection!!!")
		# yeet it
		body.get_parent().queue_free()
		#body.get_parent().get_parent().queue_free()

extends Node3D


# Declare member variables here. Examples:
var vehicles = {"car": true}
var discovered_roads = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func save_game():
	var save_data = File.new()
	save_data.open("res://savegame.txt", File.WRITE)
	
	var player = get_tree().get_nodes_in_group("player")[0]
	
	save_data.store_line(var2str(player.get_node("BODY").global_transform))
	save_data.store_line(var2str(get_node("scene").time))
	save_data.store_line(var2str(player.get_node("BODY").distance_int))
	save_data.store_line(var2str(vehicles))
	save_data.store_line(var2str(discovered_roads))

	save_data.close()
	print("Saved game to file!")
	
func load_game():
	var data = []
	var file = File.new()
	var opened = file.open("res://savegame.txt", file.READ)
	if opened == OK:
		while !file.eof_reached():
			#var csv = file.get_csv_line()
			var line = file.get_line()
			if line != null:
				# skip empty
				if line == "":
					continue
				var _line = str2var(line)
				data.append(_line)

	
		file.close()
	
	# now load the data
	var player = get_tree().get_nodes_in_group("player")[0]
	player.get_node("BODY").global_transform = data[0]
	#print("Loaded transform, ", data[0])
	
	get_node("scene").time = data[1]
	player.get_node("BODY").distance_int = data[2]
	player.get_node("BODY").distance = data[2]
	vehicles = data[3]
	discovered_roads = data[4]
	
	
	get_tree().set_pause(false)
	get_tree().set_pause(true)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

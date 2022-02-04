@tool # because it's used by some tool scripts
extends Node


var level = 6 #default for editor use

# Logging levels - the array and the integers should be matching
const LEVELS = ["VERBOSE", "DEBUG", "INFO", "WARN", "ERROR", "ROAD_GEN", "MAPGEN"]
const VERBOSE = 0
const DEBUG = 1
const INFO = 2
const WARN = 3
const ERROR = 4
# new, custom
const ROAD_GEN = 5
const MAPGEN = 6

var data = []

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_level(lvl):
	level = lvl

func road_print(string):
	if level == ROAD_GEN:
		print(string)
		data.append(string)

func mapgen_print(string):
	if level == MAPGEN:
		print(string)
		data.append(string)
		
func error_print(string):
	if level == ERROR:
		print(string)

		
func save_to_file():
	var save_data = File.new()
	save_data.open("res://gen_data.txt", File.WRITE)

	for line in data:
		# Store as a new line in the save file.
		save_data.store_line(var2str(line))
	save_data.close()
	print("Saved map gen to file!")

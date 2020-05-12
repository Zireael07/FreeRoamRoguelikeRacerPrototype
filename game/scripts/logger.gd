tool # because it's used by some tool scripts
extends Node


var level = 4 #default for editor use

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

func mapgen_print(string):
	if level == MAPGEN:
		print(string)
		
func error_print(string):
	if level == ERROR:
		print(string)

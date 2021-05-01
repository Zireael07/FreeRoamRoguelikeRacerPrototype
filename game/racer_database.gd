extends Node


# Declare member variables here. Examples:
var romaji1_list = ["Ji", "Sabu", "Shi", "Go", "Roku", "Shichi", "Hachi", "Ku"] #["Ichi", 
var name1_list = ["ニ", "三", "四", "五", "六", "七", "八", "九"] #["一", 
var romaji2_list = ["ro"]
var name2_list = ["郎"]

var racers_list = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# put racers into base
	for i in range(0, romaji1_list.size()):
	#for r in romaji1_list:
		var s_name = name1_list[i] + name2_list[0]
		var s_romaji = romaji1_list[i] + romaji2_list[0]
	
		#print("Romaji: ", s_romaji)
		# we don't have Dictionary.append, so just create
		racers_list[s_romaji] = [s_name, s_romaji]
		#racers_list.append([s_name, s_romaji])

func random_pick():
	var rand_one = randi() % racers_list.size()-1
	var key = racers_list.keys()[rand_one]
	return racers_list[key]

func on_picked_name(romaji):
	racers_list.erase(romaji)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

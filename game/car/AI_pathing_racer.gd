extends "AI_pathing.gd"

# class member variables go here, for example:

export(String) var AI_name = "一郎"
export(String) var romaji = "Ichiro"

onready var panel = get_node("BODY").get_node("Viewport").get_node("Nametag")
#onready	var nameplate = get_node("BODY").get_node("Viewport1").get_node("nameplate")

var romaji1_list = ["Ichi", "Ji", "Sabu", "Shi", "Go", "Roku", "Shichi", "Hachi", "Ku"]
var name1_list = ["一", "ニ", "三", "四", "五", "六", "七", "八", "九"]
var romaji2_list = ["ro"]
var name2_list = ["郎"]

var race

func _ready():
	._ready()
	random_name()
	if race:
		get_node("BODY").connect("path_gotten", race, "_on_path_gotten")
	
func random_name():
	# seed the rng
	randomize()
	
	var rand_one = randi() % 9
	
	var s_name = name1_list[rand_one] + name2_list[0]
	var s_romaji = romaji1_list[rand_one] + romaji2_list[0]
	
	select_name(s_name, s_romaji)


func select_name(s_name, s_romaji):
	print("Selected name " + s_name + " " + s_romaji)
	AI_name = s_name
	romaji = s_romaji
	
	set_our_name()
	
func set_our_name():
	print("Setting AI name " + String(romaji))
	
	if AI_name != "" and romaji != "":
		#panel.set_name(romaji)
		panel.get_node("Label").set_text(romaji)
		
		print("AI panel name " + panel.name)
		#nameplate.set_name(AI_name)
		#print("AI nameplate " + nameplate.name)

extends "AI_pathing.gd"

# class member variables go here, for example:

@export var AI_name: String = "一郎"
@export var romaji: String = "Ichiro"

@onready var panel = get_node(^"BODY").get_node(^"SubViewport").get_node(^"Nametag")
#onready	var nameplate = get_node(^"BODY").get_node(^"Viewport1").get_node(^"nameplate")

var romaji1_list = ["Ichi", "Ji", "Sabu", "Shi", "Go", "Roku", "Shichi", "Hachi", "Ku"]
var name1_list = ["一", "ニ", "三", "四", "五", "六", "七", "八", "九"]
var romaji2_list = ["ro"]
var name2_list = ["郎"]

var race
var race_int_path = []
var race_target = null

func _ready():
	#._ready()
	if is_in_group("race_AI"):
		print("Race AI pathing")
		# we don't need to look up map itself, so let's make it a shortcut to nav
		map = get_node(^"/root/Node3D").get_node(^"map").get_node(^"nav")
		var lookup_path = map.path_look[[race_int_path[0], race_int_path[1]]]
		#print("[AI] Lookup path: " + str(lookup_path))
		var nav_path = map.nav.get_point_path(lookup_path[0], lookup_path[1])
		
		path = racer_reduce_path(nav_path)
		# append target point
		path.append(race_target)
		
		# append final point
		# B-A = A->B
		var dir = (race_target-path[path.size()-2]).normalized()*6
		path.append(race_target+dir)
		
		#print("AI has path: " + str(path))
		emit_signal("found_path", [path, false, false])
		
	#random_name()
	pick_from_base()
	
	# Initialization here
	if has_node("draw"):
		draw = get_node(^"draw")
	if has_node("draw2"):
		draw_arc = get_node(^"draw2")
	
#	if race:
#		print("Connect race " + str(race) + " to path_gotten")
#		get_node(^"BODY").connect(&"path_gotten", race._on_path_gotten)
#		print(get_node(^"BODY").is_connected("path_gotten", race, "_on_path_gotten"))
#		print(str(get_node(^"BODY").get_signal_connection_list("path_gotten")))
	
func random_name():
	# seed the rng
	randomize()
	
	var rand_one = randi() % 9
	
	var s_name = name1_list[rand_one] + name2_list[0]
	var s_romaji = romaji1_list[rand_one] + romaji2_list[0]
	
	select_name(s_name, s_romaji)


func pick_from_base():
	var data = RacerDatabase.random_pick()
	RacerDatabase.on_picked_name(data[1])
	select_name(data[0], data[1])

func select_name(s_name, s_romaji):
	print("Selected name " + s_name + " " + s_romaji)
	AI_name = s_name
	romaji = s_romaji
	
	set_our_name()
	
func set_our_name():
	print("Setting AI name " + String(romaji))
	
	if AI_name != "" and romaji != "":
		#panel.set_name(romaji)
		panel.get_node(^"Label").set_text(romaji)
		
		#print("AI panel name " + var2str(panel.name))
		#nameplate.set_name(AI_name)
		#print("AI nameplate " + nameplate.name)

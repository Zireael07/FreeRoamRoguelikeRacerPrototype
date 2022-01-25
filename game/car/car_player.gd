extends Node3D

# class member variables go here, for example:

@export var player_name: String = "一郎"
@export var romaji: String = "Ichiro"

@onready var panel = get_node(^"BODY").get_node(^"SubViewport").get_node(^"Nametag")
@onready	var nameplate = get_node(^"BODY").get_node(^"SubViewport 2").get_node(^"nameplate")


func _ready():
	set_name_custom()
	
	# hack fix
	if rotation.y != 0:
		get_node(^"BODY").rotate_y(rotation.y)
		rotation.y = 0
	
	#pass
	
func select_name(s_name, s_romaji):
	#print("Selected name " + s_name + " " + s_romaji)
	player_name = s_name
	romaji = s_romaji
	
	set_name_custom()
	
func set_name_custom():
	#print("Setting name " + String(romaji))
	
	if player_name != "" and romaji != "":
		panel.set_name(romaji)
		#print("Panel name " + panel.name)
		nameplate.set_name(player_name)
		#print("Nameplate " + nameplate.name)

func freeze_viewports():
	get_node(^"BODY/SubViewport").set_update_mode(SubViewport.UPDATE_DISABLED)
	get_node(^"BODY/SubViewport 2").set_update_mode(SubViewport.UPDATE_DISABLED)

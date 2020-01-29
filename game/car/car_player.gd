extends Spatial

# class member variables go here, for example:

export(String) var player_name = "一郎"
export(String) var romaji = "Ichiro"

onready var panel = get_node("BODY").get_node("Viewport").get_node("Nametag")
onready	var nameplate = get_node("BODY").get_node("Viewport 2").get_node("nameplate")


func _ready():
	set_name_custom()
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
	get_node("BODY/Viewport").set_update_mode(Viewport.UPDATE_DISABLED)
	get_node("BODY/Viewport 2").set_update_mode(Viewport.UPDATE_DISABLED)

extends Control

# class member variables go here, for example:
var player
var changed = false

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	get_node(^"MoneyLabel").set_text(str(player.money))
	
	check_owned()

func check_owned():
	if player.is_in_group("bike"):
		if get_parent().get_node(^"bike").is_visible():
			get_node(^"ButtonBuy").set_disabled(true)
		else:
			get_node(^"ButtonBuy").set_disabled(false)
	else:
		if get_parent().get_node(^"car").is_visible():
			get_node(^"ButtonBuy").set_disabled(true)
		else:
			get_node(^"ButtonBuy").set_disabled(false)
	
func _on_Button_pressed():
	print("Going back to the city...")	
	get_parent().go_back()

func _on_ButtonLeft_pressed():
	if get_parent().get_node(^"car").is_visible():
		get_parent().get_node(^"car").hide()
		get_parent().get_node(^"bike").show()
	elif get_parent().get_node(^"bike").is_visible():
		get_parent().get_node(^"bike").hide()
		get_parent().get_node(^"car").show()
	
	check_owned()


func _on_ButtonRight_pressed():
	if get_parent().get_node(^"car").is_visible():
		get_parent().get_node(^"car").hide()
		get_parent().get_node(^"bike").show()
	elif get_parent().get_node(^"bike").is_visible():
		get_parent().get_node(^"bike").hide()
		get_parent().get_node(^"car").show()

	check_owned()

func _on_ButtonBuy_pressed():
	if get_parent().get_node(^"car").is_visible():
		# we start in a car, nothing to do here
		pass
	elif get_parent().get_node(^"bike").is_visible():
		print("Bought a bike")
		changed = true
		#player.swap_to_bike()

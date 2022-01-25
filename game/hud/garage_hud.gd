extends Control

# class member variables go here, for example:
var player
var root
var vehicles = {}

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	get_node(^"MoneyLabel").set_text(str(player.money))
	
	# disable buttons if too little money	
	disable_buttons_money()
	disable_buttons_switch()

	
func disable_buttons_switch():
	if root.vehicles.keys().size() < 2:
		get_node(^"ButtonLeft").hide()
		get_node(^"ButtonLeft").set_disabled(true)
		get_node(^"ButtonRight").hide()
		get_node(^"ButtonRight").set_disabled(true)
	else:
		# if we're driving a bike, show it in garage
		if root.vehicles["bike"] == true:
			get_parent().get_node(^"Spatial3").show()
			get_parent().get_node(^"Spatial2").hide()
			

func disable_buttons_money():
	if player.money < 60:
		get_node(^"Control/EngineBlock/EngineButton2").set_disabled(true)
		print("Disable engine 2")
	
	if player.money < 40:
		get_node(^"Control/EngineBlock/EngineButton").set_disabled(true)
		print("Disable engine 1")
		
	if player.money < 20:
		get_node(^"Control/BrakesBlock/BrakeButton2").set_disabled(true)
	
	if player.money < 10:
		get_node(^"Control/BrakesBlock/BrakeButton").set_disabled(true)	

func _on_Button_pressed():
	print("Going back to the city...")	
	get_parent().go_back()


# ----------------------------
func _on_BrakeButton_pressed():
	player.braking_power = -15.0
	player.money = player.money - 10
	get_node(^"MoneyLabel").set_text(str(player.money))
	disable_buttons_money()


func _on_BrakeButton2_pressed():
	player.braking_power = -25.0
	player.money = player.money - 20
	get_node(^"MoneyLabel").set_text(str(player.money))
	disable_buttons_money()


#func _on_TireButton_pressed():
#	print("Pressed tire")
#	player.get_node(^"wheel1").set_friction_slip(1.5)
#	player.get_node(^"wheel2").set_friction_slip(1.5)
#	player.get_node(^"wheel3").set_friction_slip(1.5)
#	player.get_node(^"wheel4").set_friction_slip(1.5)


func _on_EngineButton_pressed():
	player.engine_power = 9.0
	player.money = player.money - 40
	get_node(^"MoneyLabel").set_text(str(player.money))
	disable_buttons_money()


func _on_EngineButton2_pressed():
	player.engine_power = 12.0
	player.money = player.money - 60
	get_node(^"MoneyLabel").set_text(str(player.money))
	disable_buttons_money()

# fancy drawing disabled buttons
func _on_EngineButton_draw():
	# disabled
	if get_node(^"Control/EngineBlock/EngineButton").get_draw_mode() == 3:
		get_node(^"Control/EngineBlock/EngineButton").set_modulate(Color(1,0,0,1))


func _on_EngineButton2_draw():
	# disabled
	if get_node(^"Control/EngineBlock/EngineButton2").get_draw_mode() == 3:
		get_node(^"Control/EngineBlock/EngineButton2").set_modulate(Color(1,0,0,1))


func _on_BrakeButton_draw():
	# disabled
	if get_node(^"Control/BrakesBlock/BrakeButton").get_draw_mode() == 3:
		get_node(^"Control/BrakesBlock/BrakeButton").set_modulate(Color(1,0,0,1))


func _on_BrakeButton2_draw():
	# disabled
	if get_node(^"Control/BrakesBlock/BrakeButton2").get_draw_mode() == 3:
		get_node(^"Control/BrakesBlock/BrakeButton2").set_modulate(Color(1,0,0,1))

# switching between owned vehicles 
func _on_ButtonLeft_pressed():
	print("Left button pressed")
	if get_parent().get_node(^"Spatial2").is_visible():
		get_parent().get_node(^"Spatial2").hide()
		get_parent().get_node(^"Spatial3").show()
		vehicles = {"car": false, "bike": true}
	elif get_parent().get_node(^"Spatial3").is_visible():
		get_parent().get_node(^"Spatial3").hide()
		get_parent().get_node(^"Spatial2").show()
		vehicles = {"car":true, "bike": false}

func _on_ButtonRight_pressed():
	print("Right button pressed")
	if get_parent().get_node(^"Spatial2").is_visible():
		get_parent().get_node(^"Spatial2").hide()
		get_parent().get_node(^"Spatial3").show()
		vehicles = {"car": false, "bike": true}
	elif get_parent().get_node(^"Spatial3").is_visible():
		get_parent().get_node(^"Spatial3").hide()
		get_parent().get_node(^"Spatial2").show()
		vehicles = {"car":true, "bike": false}

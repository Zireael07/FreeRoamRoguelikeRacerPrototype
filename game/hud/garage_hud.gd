extends Control

# class member variables go here, for example:
var player

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	get_node("MoneyLabel").set_text(str(player.money))
	
	# disable buttons if too little money	
	disable_buttons_money()
	
	
	#pass

func disable_buttons_money():
	if player.money < 60:
		get_node("Control/EngineBlock/EngineButton2").set_disabled(true)
		print("Disable engine 2")
	
	if player.money < 40:
		get_node("Control/EngineBlock/EngineButton").set_disabled(true)
		print("Disable engine 1")
		
	if player.money < 20:
		get_node("Control/BrakesBlock/BrakeButton2").set_disabled(true)
	
	if player.money < 10:
		get_node("Control/BrakesBlock/BrakeButton").set_disabled(true)	

func _on_Button_pressed():
	print("Going back to the city...")
	
	get_parent().go_back()
	
	pass # replace with function body


func _on_BrakeButton_pressed():
	player.braking_force_mult = 6
	player.money = player.money - 10
	get_node("MoneyLabel").set_text(str(player.money))
	disable_buttons_money()


func _on_BrakeButton2_pressed():
	player.braking_force_mult = 8
	player.money = player.money - 20
	get_node("MoneyLabel").set_text(str(player.money))
	disable_buttons_money()


func _on_TireButton_pressed():
	print("Pressed tire")
	player.get_node("wheel1").set_friction_slip(1.5)
	player.get_node("wheel2").set_friction_slip(1.5)
	player.get_node("wheel3").set_friction_slip(1.5)
	player.get_node("wheel4").set_friction_slip(1.5)


func _on_EngineButton_pressed():
	player.engine_force_mult = 1.5
	player.money = player.money - 40
	get_node("MoneyLabel").set_text(str(player.money))
	disable_buttons_money()


func _on_EngineButton2_pressed():
	player.engine_force_mult = 2
	player.money = player.money - 60
	get_node("MoneyLabel").set_text(str(player.money))
	disable_buttons_money()

# fancy drawing disabled buttons
func _on_EngineButton_draw():
	# disabled
	if get_node("Control/EngineBlock/EngineButton").get_draw_mode() == 3:
		get_node("Control/EngineBlock/EngineButton").set_modulate(Color(1,0,0,1))


func _on_EngineButton2_draw():
	# disabled
	if get_node("Control/EngineBlock/EngineButton2").get_draw_mode() == 3:
		get_node("Control/EngineBlock/EngineButton2").set_modulate(Color(1,0,0,1))


func _on_BrakeButton_draw():
	# disabled
	if get_node("Control/BrakesBlock/BrakeButton").get_draw_mode() == 3:
		get_node("Control/BrakesBlock/BrakeButton").set_modulate(Color(1,0,0,1))


func _on_BrakeButton2_draw():
	# disabled
	if get_node("Control/BrakesBlock/BrakeButton2").get_draw_mode() == 3:
		get_node("Control/BrakesBlock/BrakeButton2").set_modulate(Color(1,0,0,1))

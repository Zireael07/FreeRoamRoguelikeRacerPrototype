extends Spatial

# class member variables go here, for example:
var player
var player_script #= load("res://car/vehicle_player.gd")
var dealer_scene

func _ready():
	dealer_scene = preload("res://objects/dealer_inside.tscn")
	player_script = load("res://car/vehicle_player.gd")
	# Called every time the node is added to the scene.
	# Initialization here

func enter_dealer(body):
	print("dealer entrance area entered by the player")
	player = body
	
	# hide normal gui
	var hud = player.get_node("root")
	var map = player.get_node("Viewport_root") #"/Viewport/minimap")
	hud.hide()
	map.hide()
	
	# hide ourselves
	hide()
	
	# hide the original car (for now)
	player.hide()
	
	# brake
	#player.set_engine_force(-player.get_engine_force())
	player.set_translation(player.get_translation())
	#player.set_engine_force(-400)
	
	# stop car input
	player.set_physics_process(false)
	
	# stop time passage
	var root = get_parent().get_parent() #.get_parent() #.get_parent()
	print(root.get_name())
	var world = root.get_node("World")
	world.set_process(false)
	# hide the sun
	root.get_node("DirectionalLight").set_visible(false)
	
	var env = root.get_node("WorldEnvironment").get_environment()
	env.set_fog_enabled(false)
	
	#spawn dealer interior scene
	var dealer_interior = dealer_scene.instance()
	dealer_interior.translate(get_translation())
	dealer_interior.rotate_y(get_rotation().y)
	
	dealer_interior.set_name("dealer_interior")
	
	# save stuff to be unhidden
	dealer_interior.player = player
	dealer_interior.entrance = self
	
	dealer_interior.env = env
	
	root.add_child(dealer_interior)



func _on_Area_body_entered( body ):
	print("Area triggered")
	if body is VehicleBody:
		if body is player_script:
			if body.speed < 10:
				enter_dealer(body)
			else:
				print("Going too fast!")
			

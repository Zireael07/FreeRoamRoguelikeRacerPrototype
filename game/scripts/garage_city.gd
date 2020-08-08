extends Spatial

# class member variables go here, for example:
var player
var player_script #= load("res://car/vehicle_player.gd")
var garage_scene

func _ready():
	garage_scene = preload("res://objects/garage_inside.tscn")
	player_script = load("res://car/vehicle_player.gd")
	# Called every time the node is added to the scene.
	# Initialization here
	pass


func _on_Area_body_entered( body ):
	print("Area triggered")
	if body is VehicleBody:
		if body is player_script:
			print("Garage entrance area entered by the player")
			player = body
			
			# hide normal gui
			var hud = player.get_node("root")
			var map = player.get_node("Viewport_root") #/Viewport/minimap")
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
			var root = get_parent().get_parent().get_parent().get_parent()
			print(root.get_name())
			var world = root.get_node("World")
			world.set_process(false)
			# hide the sun
			root.get_node("DirectionalLight").set_visible(false)
			
			var env = root.get_node("WorldEnvironment").get_environment()
			env.set_fog_enabled(false)
			
			#spawn garage interior scene
			var garage_interior = garage_scene.instance()
			garage_interior.translate(get_translation())
			garage_interior.rotate_y(get_rotation().y)
			
			garage_interior.set_name("garage_interior")
			
			# save stuff to be unhidden
			garage_interior.player = player
			garage_interior.entrance = self
			
			garage_interior.env = env
			
			root.add_child(garage_interior)
			
			
	
	
	#pass # replace with function body

extends Spatial

# class member variables go here, for example:
var player
var entrance
var garage_hud
var env

func _ready():
	
	# fix issues with fog
	get_node("Camera").set_current(true)
	get_node("Camera").set_environment(env)
	
	##GUI
	var h = preload("res://hud/garage_hud.tscn")
	garage_hud = h.instance()
	#garage_hud.player = player
	add_child(garage_hud)
	
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func go_back():
	if (player != null and entrance != null):
		# remove ourselves
		queue_free()
		
		# set player cam as current
		player.get_node("cambase").get_node("Camera").make_current()
		
		# move the player out of the garage
		print("Moving the player")
		player.translate(Vector3(10,0,20))
		
		# unhide player
		player.show()
		# unhide gui
		var hud = player.get_node("root")
		var map = player.get_node("Viewport_root/Viewport/minimap")
		hud.show()
		map.show()
		
		#unhide entrance
		entrance.show()
	
		#restore car input
		player.set_physics_process(true)
			
		# restore time passage
		var root = entrance.get_parent().get_parent().get_parent()
		var world = root.get_node("World")
		world.set_physics_process(true)
		# show the sun
		root.get_node("DirectionalLight").set_visible(true)
	
	
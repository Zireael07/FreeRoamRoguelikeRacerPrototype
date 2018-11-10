extends Spatial

# class member variables go here, for example:
var player
var player_script
var time
var count
#start/finish
#var finish = false
#var start

#export var target = Vector3()

func _ready():
	player_script = load("res://car/vehicle_player.gd")
	count = false

	#set_process(true)
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _on_Area_body_enter( body ):
	if body is VehicleBody:
		if body is player_script:
			print("Area entered by the player - speed")
			player = body
			
			var speed = player.get_linear_velocity().length()
			var speed_kph = round(speed*3.6)

			var msg = body.get_node("Messages")
			#msg.set_initial(false)
			msg.set_text("TEST SPEED! " + "\n" + "Speed at marker is " + str(speed_kph))
			if not msg.get_node("OK_button").is_connected("pressed", self, "_on_ok_click"):
				print("Not connected")
				msg.get_node("OK_button").connect("pressed", self, "_on_ok_click")
			else:
				print("Connected")
			
			msg.enable_ok(true)
			msg.show()
			
			# prize
			if speed_kph > 60: # more than the speed limit
				player.money += 30
			
		#else:
		#	print("Area entered by a car " + body.get_parent().get_name())
	#else:
	#	print("Area entered by something else")


func _on_ok_click():
	#count = true
	#time = 0.0
	#spawn_finish(self)
	print("Clicked ok!")
	var msg = player.get_node("Messages")
	msg.hide()


func _process(delta):
	if count:
		time += delta
		#print("Timer is " + str(time))
		player.get_node("root").get_node("Label timer").show()
		player.get_node("root").update_timer(str(time))
	#else:
	#	print("Count is off")

func _on_Area_body_exit( body ):
	if body is VehicleBody:
		if body is player_script:
			print("Area exited by the player")
			player = body
			#var msg = body.get_node("Messages")
			#msg.hide()

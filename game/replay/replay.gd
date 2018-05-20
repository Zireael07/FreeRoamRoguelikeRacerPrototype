extends AnimationPlayer

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	if get_current_animation() != "":
		print(get_parent().get_name() + " Playing..." + str(get_current_animation()))
		print("Length: " + str(get_current_animation_length()))

#	pass


func _on_replay_animation_finished(anim_name):
	print(get_parent().get_name() + " finished..." + str(anim_name))
	
	pass # replace with function body

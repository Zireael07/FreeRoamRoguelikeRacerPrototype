extends Spatial

var iTime=0.0
var iFrame=0
var env = null

func _ready():
	env = get_parent().get_node("WorldEnvironment").get_environment()
	pass

func _process(delta):
	iTime+=delta
	iFrame+=1

func steep_scb(value):
	pass # Replace with function body.

func _on_Sky_sky_updated():
	$Sky.copy_to_environment(env)
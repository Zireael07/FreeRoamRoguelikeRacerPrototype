extends Viewport

signal sky_updated

onready var material = get_node("Node2D/Sprite2").material
var trigger_count = 0

func _ready():
	# force update
	_trigger_update_sky()


func copy_to_environment(environment):
	# This is a bit of a hack, when the sky texture is assigned to our panorama Godot calculates a few things from the data
	# This happens just once, and it happens when the texture is assigned to the sky.
	# Unfortunately that means that if we assign our viewport texture before it renders, or if it is already assigned and
	# we update its contents, nothing renders correctly.
	# Hence we get this signal a few frames after the render has completed and we recreate a few things to force it to update
	
	# get the sky of our current camera
	var sky = environment.background_sky
	
	# first clear our texture
	sky.set_panorama(null)
	
	# with our proxy fix #18159 (Thanks ShyRed!) in place we don't need the expensive copy anymore
	sky.set_panorama(get_texture())
	
	
func _trigger_update_sky():
	# trigger an update
	render_target_update_mode = Viewport.UPDATE_ONCE
	
	# delay sending out our changed signal
	trigger_count = 2
	
	# restore original
	render_target_update_mode = Viewport.UPDATE_ALWAYS

func _process(delta):
	# We don't seem to have a way to detect if the viewport has actually been updated so we just wait a few frames
	if trigger_count > 0:
		trigger_count -= 1
		if trigger_count == 0:
			emit_signal("sky_updated")

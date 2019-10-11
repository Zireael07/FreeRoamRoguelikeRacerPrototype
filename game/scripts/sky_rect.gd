extends ColorRect

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_sun(value):
	self.material.set("shader_param/sun_pos", value)
	get_parent().get_parent()._trigger_update_sky()
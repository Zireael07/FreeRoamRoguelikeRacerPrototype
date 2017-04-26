extends Quad

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	get_material_override().set_texture(FixedMaterial.PARAM_DIFFUSE, get_parent().get_node("Viewport").get_render_target_texture())
	pass

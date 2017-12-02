extends MeshInstance

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	if (get_parent().get_node("Viewport 2") != null):
		print("Setting a nameplate")
		
		# Set the quad's albedo texture to the viewport texture
		var tex = get_parent().get_node("Viewport 2").get_texture()
		get_material_override().albedo_texture = tex
		
	pass

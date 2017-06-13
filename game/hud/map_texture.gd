extends TextureFrame

# class member variables go here, for example:
var texture
var uv_offset

func _ready():
	if not get_tree().is_editor_hint():
		texture = get_texture()
		uv_offset = 1/get_size().x #assume the node's scale is 1,1
		#print("UV offset is " + String(uv_offset))		
		
	#register ourselves with the minimap root
	get_parent().get_parent().get_parent().minimap_bg = self
		
	pass

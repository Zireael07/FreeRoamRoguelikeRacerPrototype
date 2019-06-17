# workaround for Godot "viewport texture" resource issue
tool
extends MeshInstance

var dummy = null
var camera = null


func _ready():
	#$"../Viewport".set_size(Vector2(1024/2, 600/2))
	
	$"../Viewport".set_update_mode(Viewport.UPDATE_ALWAYS)
	
	var t = $"../Viewport".get_texture()
	#get_material_override().albedo_texture = t
	get_material_override().set_shader_param("refl_tx", t)
	
	$"../Viewport".set_update_mode(Viewport.UPDATE_DISABLED)
	
	#get_surface_material(0).albedo_texture = t
	
	# cameras
	dummy = $"../CameraDummy"
	camera = $"../Viewport/CameraCockpitBack"

# update cam
func _process(delta):
	if Engine.is_editor_hint():
		return 
		
	if not get_tree().get_nodes_in_group("player")[0].get_node("BODY").cockpit_cam.is_current():
		return
	
	camera.global_transform = dummy.global_transform
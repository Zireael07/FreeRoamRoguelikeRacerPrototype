extends Area3D

# Declare member variables here. Examples:
var mat = preload("res://assets/car/car_blue.tres")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func debug_draw(tg):
	var props_par = get_node(^"../..")
	# debug
	var mesh = BoxMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance3D.new()
	node.set_mesh(mesh)
	node.get_mesh().surface_set_material(0, mat)
	node.set_cast_shadows_setting(0)
	node.set_name("Debug")
	props_par.add_child(node)
	node.set_translation(tg+Vector3(0,1,0))

func _on_Spatial_body_entered(body):
	#print(body, "entered avoid area")
	if body is CharacterBody3D:
		if body.get_parent().is_in_group("player"):
			var road = get_node(^"../../../../..")
			print("Player entered avoid area ", get_parent().get_name(), " rot: ", get_parent().rotation.y)
			#print("Player entered avoid area for ", road.get_name() + " @ ", body.get_global_transform().origin)
		
			var tg = $Position3D
			# debug
			#$Position3D/MeshInstance3D.get_mesh().surface_set_material(0, mat)
			#debug_draw(tg)
		if body.get_parent().is_in_group("AI") or body.get_parent().is_in_group("cop") or body.get_parent().is_in_group("race_AI"):
			print("AI in avoid area")
			# ignore points behind us
			
			body.current = 201 # special
			body.brain.target = $Position3D.global_position
			print("AI targets the special target")
			
			# trick
			# deactivate other area if any
			#if get_parent().

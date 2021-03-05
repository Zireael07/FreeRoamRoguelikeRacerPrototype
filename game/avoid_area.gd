extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Spatial_body_entered(body):
	if body is VehicleBody:
		if body.get_parent().is_in_group("player"):
			var road = get_node("../../../../..")
			
			var int0 = road.get_child(0).get_global_transform().origin
			var int1 = road.get_child(1).get_global_transform().origin
			
			# which end are we closer to?
			var dist0 = body.get_global_transform().origin.distance_to(int0)
			var dist1 = body.get_global_transform().origin.distance_to(int1)
			
			var tg_end = -1
			
			if dist0 < dist1:
				print("Closer to dist0, head for dist1 + offset")
				tg_end = 1
			else:
				print("Closer to dist1, head for dist0 + offset")
				tg_end = 0
				
			var props_par = get_node("../..")
			
			# tg is local to props_par (the same space we're placed in)
			var tg = props_par.get_global_transform().origin + props_par.to_local(int0)
			if tg_end == 1:
				tg = props_par.get_global_transform().origin + props_par.to_local(int0)
			
			var loc = props_par.to_local(get_global_transform().origin)
			
			tg.x = loc.x # should set target straight ahead of us
			
			print("Player entered avoid area for ", road.get_name() + " @ ", body.get_global_transform().origin)
		
			#body.debug_cube(body.to_local(tg))
			
			# debug
			var mesh = CubeMesh.new()
			mesh.set_size(Vector3(0.5,0.5,0.5))
			var node = MeshInstance.new()
			node.set_mesh(mesh)
			node.set_cast_shadows_setting(0)
			node.set_name("Debug")
			props_par.add_child(node)
			node.set_translation(loc+Vector3(0,1,0))
		
		if body.get_parent().is_in_group("cop"):
			var road = get_node("../../../../..")
			print("AI cop entered avoid area for ", road.get_name() + "@ ", body.get_global_transform().origin)
	
	pass # Replace with function body.

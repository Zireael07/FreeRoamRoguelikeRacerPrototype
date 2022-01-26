extends Area3D


# Declare member variables here. Examples:
var mat = preload("res://assets/car/car_blue.tres")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func get_target(body):
	var road = get_node(^"../../../../..")
			
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
		
	var props_par = get_node(^"../..")
	
	# tg is local to props_par (the same space we're placed in)

	# offset to ensure we have space to maneuver around the building's corner
	var offset = 8
	var tg = Vector3(0,0,-offset) # props_par starts where the road starts
	if tg_end == 1:
		#tg = props_par.to_local(int1)
		tg = props_par.get_parent().relative_end
		tg.z = tg.z + offset
		
	var loc_self = props_par.to_local(get_global_transform().origin)
	
	tg.x = loc_self.x # should set target straight ahead of us
	
	return tg

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
	if body is VehicleBody3D:
		if body.get_parent().is_in_group("player"):
			var road = get_node(^"../../../../..")
			#print("Player entered avoid area for ", road.get_name() + " @ ", body.get_global_transform().origin)
		
			var tg = get_target(body)
			#debug_draw(tg)
		
		if body.get_parent().is_in_group("cop"):
			var road = get_node(^"../../../../..")
			print("AI cop entered avoid area for ", String(road.get_name()) + "@ ", body.get_global_transform().origin)
	
			var brain = body.get_node(^"brain")
			if brain.get_state() != brain.STATE_BUILDING:
				var tg = get_target(body)
				debug_draw(tg)
				# convert to global space for AI target
				var props_par = get_node(^"../..")
				brain.set_state(brain.STATE_BUILDING, props_par.get_global_transform().origin + tg)
	

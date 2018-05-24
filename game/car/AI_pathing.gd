extends Node

# class member variables go here, for example:
export(Vector3) var target = Vector3(0,0,0)
export(bool) var left = true

var navigation_node

# debugging
var draw
var draw_arc

func _ready():
	# Called every time the node is added to the scene.
	
	navigation_node = get_node("/root/root")
	
	# Initialization here
	if has_node("draw"):
		draw = get_node("draw")
	if has_node("draw2"):
		draw_arc = get_node("draw2")
	
	#pass

func find_path():
	if (navigation_node != null):
		#print("We have a navigation node")
		
		# enable the navmesh we're interested in
		if (left):
			get_tree().call_group("right_lane", "set_enabled", false)
			get_tree().call_group("left_lane", "set_enabled", true)
		else:
			get_tree().call_group("left_lane", "set_enabled", false)
			get_tree().call_group("right_lane", "set_enabled", true)
		
		# get the points on navmesh relative to ourselves and target
		var pos = get_translation()
		var source = navigation_node.get_closest_point(pos)
		print(get_name() + " looking for closest point to own position : " + String(pos) + " is " + String(source))
		var t = navigation_node.get_closest_point(target)
		print(get_name() + " looking for closest point to target : " + String(target) + " is " + String(t))
		#print("Trying to find path from " + String(source) + " to " + String(t))
		var path = navigation_node.get_simple_path(source, t)
		
		
		if (path.size() > 0):
			#print(get_name() + " has a path " + String(path))
			print(get_name() + " AI has a path")				
			
			return path
		else:
			#print("No path")
			return null
			
func debug_cube(loc):
	var mesh = CubeMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance.new()
	node.set_mesh(mesh)
	add_child(node)
	node.set_translation(loc)
	
	
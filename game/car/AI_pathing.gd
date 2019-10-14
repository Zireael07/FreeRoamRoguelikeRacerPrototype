extends Spatial

# class member variables go here, for example:
export(Vector3) var target = Vector3(0,0,0)
export(bool) var left = true

var path

#var navigation_node
var map

# debugging
var draw
var draw_arc

func _ready():
	# Called every time the node is added to the scene.
	
	#navigation_node = get_node("/root/root")
	# only traffic AI
	if is_in_group("AI"):
		map = get_node("/root/Navigation").get_node("map")
		
		# look up the closest intersection
		var map_loc = map.to_local(get_global_transform().origin)
		#print("global: " + str(get_global_transform().origin) + ", map_loc: " + str(map_loc))
		
		var sorted = map.sort_intersections_distance(map_loc, true)
		var closest_ind = sorted[0][1]
		
		var closest = map.get_child(closest_ind)
		print(closest.get_name() + " " + str(closest.get_translation()))
		
		#print("[AI] Path_look: " + str(map.path_look))
		var int_path = []
		for p in map.path_look:
			if p[0] == closest_ind-2:
				int_path = p
				
		#print("[AI] our intersection path" + str(int_path))
		
		var lookup_path = map.path_look[[int_path[0], int_path[1]]]
		#print("[AI] Lookup path: " + str(lookup_path))
		var nav_path = map.nav.get_point_path(lookup_path[0], lookup_path[1])
		#print("[AI] Nav path: " + str(nav_path))
		
		path = reduce_path(nav_path)
	
	# Initialization here
	if has_node("draw"):
		draw = get_node("draw")
	if has_node("draw2"):
		draw_arc = get_node("draw2")
	

# this used navmesh
#func find_path():
#	if (navigation_node != null):
#		#print("We have a navigation node")
#
#		# enable the navmesh we're interested in
##		if (left):
##			get_tree().call_group("right_lane", "set_enabled", false)
##			get_tree().call_group("left_lane", "set_enabled", true)
##		else:
##			get_tree().call_group("left_lane", "set_enabled", false)
##			get_tree().call_group("right_lane", "set_enabled", true)
#
#		# get the points on navmesh relative to ourselves and target
#		var pos = get_translation()
#		var source = navigation_node.get_closest_point(pos)
#		print(get_name() + " looking for closest point to own position : " + String(pos) + " is " + String(source))
#		var t = navigation_node.get_closest_point(target)
#		print(get_name() + " looking for closest point to target : " + String(target) + " is " + String(t))
#		#print("Trying to find path from " + String(source) + " to " + String(t))
#		var path = navigation_node.get_simple_path(source, t)
#
#
#		if (path.size() > 0):
#			print(get_name() + " has a path: " + str(path.size()))
#			#print(get_name() + " has a path " + String(path))
#			#print(get_name() + " AI has a path")				
#
#			# reduce number of points
#			var new_path = reduce_path(path)
#			return new_path
#
#			#return path
#		else:
#			#print("No path")
#			return null

func reduce_path(path):
	var new_path = Array(path).duplicate() # can't iterate and remove
			
	var to_remove = []
	# size()-1 is normal, deduce 2 so that i-2 works:
	for i in path.size()-3:
		# B-A = A to B
		var vec1 = path[i+1]-path[i]
		var vec2 = path[i+2]-path[i]
		var angle = vec2.angle_to(vec1) #radians
		#print("Angle diff " + str(rad2deg(angle)) + " for i: " + str(i))
		
		# if angle is the same, remove middle point
		if rad2deg(angle) < 0.01:
			#print("Removing point at: " + str(i+1) + " because angle is " + str(rad2deg(angle)))
			
			to_remove.append(path[i+1])
			# as we remove, the indices change
			#new_path.remove(i+1)
	
	# remove specified
	for p in to_remove:
		new_path.remove(new_path.find(p))
	
	
	#print("New path" + str(new_path))
	print("New path: " + str(new_path.size()))
		
	return new_path
			
func debug_cube(loc):
	var mesh = CubeMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance.new()
	node.set_mesh(mesh)
	add_child(node)
	node.set_translation(loc)
	
	
@tool
extends Node2D

# class member variables go here, for example:
var ast
var points
var edges
var distance_map

# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	# we'll use AStar to have an easy map of neighbors
	ast = AStar.new()
	points = get_node(^"Node2D").points
	for i in range(0,points.size()):
		ast.add_point(i, Vector3(points[i].x, 0, points[i].y))

	for t in get_node(^"Node2D").tris:
		#print("Edges: " + str(t.get_edges()))
		for e in t.get_edges():
			# avoid duplicates
			#if not as.get_point_connections(e[1]).has(e[0]) and not as.get_point_connections(e[0]).has(e[1]):
			ast.connect_points(e[0], e[1])

	var start = points[0]
	#print("Connections for start: " + str(as.get_point_connections(0)))
	
	distance_map = bfs_distances(0)
	
	print(str(distance_map))
	
	print("Keys: " + str(distance_map.keys()))
	printt("Values: " + str(distance_map.values()))
	
	#pass

var dist_to_color = {0:Color(0,1,0), 1:Color(0.5,0.5,0), 2:Color(1, 1, 0), 3:Color(1,0,0), 4:Color(0,0,1) }

func _draw():
	for n in distance_map.keys():
	#for n in distance_map:
		var v = distance_map[n]
		draw_circle(points[n], 2.0, dist_to_color[v])
		# test
		#draw_circle(points[n], 2.0, Color(1,1,0))


#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

# yes it could be more efficient I guess
func bfs_distances(start):
	# keep track of all visited nodes
	#var explored = []
	var distance = {}
	distance[start] = 0
	
	# keep track of nodes to be checked
	var queue = [start]
	
	# keep looping until there are nodes still to be checked
	while queue:
		# pop shallowest node (first node) from queue
		var node = queue.pop_front()
		print("Visiting... " + str(node))
		
		var neighbours = ast.get_point_connections(node)
		# add neighbours of node to queue
		for neighbour in neighbours:
			# if not visited
			#if not explored.has(neighbour):
			if not distance.has(neighbour):
				queue.append(neighbour)
				distance[neighbour] = 1 + distance[node]
		
	
	return distance
		
#		if not distance.has(node):
#		#if not explored.has(node):
#			print("Visiting... " + str(node))
#
#			# add node to list of checked nodes
#			explored.append(node)
#			var neighbours = as.get_point_connections(node)
#
#			# add neighbours of node to queue
#			for neighbour in neighbours:
#				# if not visited
#				#if not explored.has(neighbour):
#				if not distance.has(neighbour):
#					queue.append(neighbour)
   
#	return explored

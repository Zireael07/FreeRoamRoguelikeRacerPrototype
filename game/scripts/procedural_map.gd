tool
extends "connect_intersections.gd"

# class member variables go here, for example:
var intersects
var mult
	
var edges = []
var samples = []


func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	mult = get_node("triangulate/poisson").mult
	
	intersects = preload("res://roads/intersection.tscn")
	
	samples = get_node("triangulate/poisson").samples
	
	for i in range(0, get_node("triangulate/poisson").samples.size()-1):
		var p = get_node("triangulate/poisson").samples[i]
		var intersection = intersects.instance()
		intersection.set_translation(Vector3(p[0]*mult, 0, p[1]*mult))
		intersection.set_name("intersection" + str(i))
		add_child(intersection)
	
	# get the triangulation
	var tris = get_node("triangulate").tris
	
	for t in tris:
		#var poly = []
		#print("Edges: " + str(t.get_edges()))
		for e in t.get_edges():
			edges.append(e)
	
	# create the map
	for i in range(0, edges.size()):
		var ed = edges[i]
		#print("Connecting intersections for edge: " + str(i) + " 0: " + str(ed[0]) + " 1: " + str(ed[1]))
		var p1 = samples[ed[0]]
		var p2 = samples[ed[1]]
		# +1 because of the poisson node that comes first
		connect_intersections(ed[0]+2, ed[1]+2)
	
#	edges = get_node("triangulate/poisson").edges
#	#print("Edges : " + str(edges))
#
#	# cleanup
#	var edges_copy = []
#	for i in range(0,edges.size()):
#		if not edges_copy.has(edges[i]):
#			edges_copy.append(edges[i])
#
#	#print("Copy : " + str(edges_copy))
#
#
#	# create the map
#	for i in range(0, edges_copy.size()):
#		var e = edges_copy[i]
#		print("Connecting intersections for edge: " + str(i) + " 0: " + str(e[0]) + " 1: " + str(e[1]))
#		var p1 = samples[e[0]]
#		var p2 = samples[e[1]]
#		# +1 because of the poisson node that comes first
#		connect_intersections(e[0]+2, e[1]+2)
	
	
	
	#pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

# based on https://github.com/TassuP/GodotStuff/blob/master/DelaunayTriangulator/Delaunay.gd

tool
extends Node

# class member variables go here, for example:
var points = []

# I don't know the real epsilon in Godot, but this works
var float_Epsilon = 0.000001

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	#generate_points(500,500,10)
	pass
	
func setup():
	var input = get_child(0).samples
	for p in input:
		points.append(Vector2(p[0], p[1]))		#pass

func generate_points(width, height, num_points):
	
	for i in range(num_points):
		# coords
		points.append(Vector2(rand_range(0, width), rand_range(0, height)))

func _draw():
	for p in points:
		draw_circle(p, 5.0, Color(1,0,0))

func polygons(polys):
	for p in polys:
		var node = Polygon2D.new()
		var color = Color(randf(), randf(), randf(), 0.5)
		node.set_polygon(p)
		node.set_color(color)
		add_child(node)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

#################  The rest is the delaunay-code #################

# classes for delaunay
class Triangle:
	# indices
	var p1
	var p2
	var p3
	func _init(var point1, var point2, var point3):
		p1 = point1
		p2 = point2
		p3 = point3
	func get_edges():
		# can't use the Edge class below because it crashes
		return [Vector2(p1, p2), Vector2(p2, p3), Vector2(p3, p1)]

class Edge:
	var p1
	var p2
	func _init(var point1, var point2):
		p1 = point1
		p2 = point2
	func Equals(var other):
		return ((p1 == other.p2) && (p2 == other.p1)) || ((p1 == other.p1) && (p2 == other.p2))

# magic
func TriangulatePolygon(points):
	var VertexCount = points.size()
	var xmin = points[0].x
	var ymin = points[0].y
	var xmax = xmin
	var ymax = ymin
	
	var i = 0
	while(i < points.size()):
		var v = points[i]
		xmin = min(xmin, v.x)
		ymin = min(ymin, v.y)
		xmax = max(xmax, v.x)
		ymax = max(ymax, v.y)
		i += 1
	
	var dx = xmax - xmin
	var dy = ymax - ymin
	var dmax = max(dx,dy)
	var xmid = (xmax + xmin) * 0.5
	var ymid = (ymax + ymin) * 0.5
	
	var expanded = Array()
	i = 0
	while(i < points.size()):
		var v = points[i]
		#if(horizontal):
		#	expanded.append(Vector3(v.x, -v.z, v.y))
		#else:
		expanded.append(Vector2(v.x, v.y)) #, v.z))
		i += 1
	
	expanded.append(Vector2((xmid - 2 * dmax), (ymid - dmax)))
	expanded.append(Vector2(xmid, (ymid + 2 * dmax)))
	expanded.append(Vector2((xmid + 2 * dmax), (ymid - dmax)))
	
	var TriangleList = Array()
	TriangleList.append(Triangle.new(VertexCount, VertexCount + 1, VertexCount + 2));
	var ii1 = 0
	while(ii1 < VertexCount):
		var Edges = Array()
		var ii2 = 0
		while(ii2 < TriangleList.size()):
			if (TriangulatePolygonSubFunc_InCircle(expanded[ii1], expanded[TriangleList[ii2].p1], expanded[TriangleList[ii2].p2], expanded[TriangleList[ii2].p3])):
				Edges.append(Edge.new(TriangleList[ii2].p1, TriangleList[ii2].p2));
				Edges.append(Edge.new(TriangleList[ii2].p2, TriangleList[ii2].p3));
				Edges.append(Edge.new(TriangleList[ii2].p3, TriangleList[ii2].p1));
				TriangleList.remove(ii2);
				ii2-=1
			ii2+=1
		
		ii2 = Edges.size()-2
		while(ii2 >= 0):
			var ii3 = Edges.size()-1
			while(ii3 >= ii2+1):
				if (Edges[ii2].Equals(Edges[ii3])):
					Edges.remove(ii3);
					Edges.remove(ii2);
					ii3-=1
				ii3-=1
			ii2-=1
			
		ii2 = 0
		while(ii2 < Edges.size()):
			TriangleList.append(Triangle.new(Edges[ii2].p1, Edges[ii2].p2, ii1))
			ii2+=1
		Edges.clear()
		ii1 += 1
		
	ii1 = TriangleList.size()-1
	while(ii1 >= 0):
		if (TriangleList[ii1].p1 >= VertexCount || TriangleList[ii1].p2 >= VertexCount || TriangleList[ii1].p3 >= VertexCount):
			TriangleList.remove(ii1);
		ii1-=1
		
	return TriangleList
	
func TriangulatePolygonSubFunc_InCircle(p, p1, p2, p3):
	if (abs(p1.y - p2.y) < float_Epsilon && abs(p2.y - p3.y) < float_Epsilon):
		return false
	var m1
	var m2
	var mx1
	var mx2
	var my1
	var my2
	var xc
	var yc
	if (abs(p2.y - p1.y) < float_Epsilon):
		m2 = -(p3.x - p2.x) / (p3.y - p2.y)
		mx2 = (p2.x + p3.x) * 0.5
		my2 = (p2.y + p3.y) * 0.5
		xc = (p2.x + p1.x) * 0.5
		yc = m2 * (xc - mx2) + my2
	elif (abs(p3.y - p2.y) < float_Epsilon):
		m1 = -(p2.x - p1.x) / (p2.y - p1.y)
		mx1 = (p1.x + p2.x) * 0.5
		my1 = (p1.y + p2.y) * 0.5
		xc = (p3.x + p2.x) * 0.5
		yc = m1 * (xc - mx1) + my1
	else:
		m1 = -(p2.x - p1.x) / (p2.y - p1.y)
		m2 = -(p3.x - p2.x) / (p3.y - p2.y)
		mx1 = (p1.x + p2.x) * 0.5
		mx2 = (p2.x + p3.x) * 0.5
		my1 = (p1.y + p2.y) * 0.5
		my2 = (p2.y + p3.y) * 0.5
		xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2)
		yc = m1 * (xc - mx1) + my1
		
	var dx = p2.x - xc
	var dy = p2.y - yc
	var rsqr = dx * dx + dy * dy
	dx = p.x - xc
	dy = p.y - yc
	var drsqr = dx * dx + dy * dy
	return (drsqr <= rsqr)
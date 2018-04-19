tool

extends Node2D

# class member variables go here, for example:
export(int) var radius = 15 setget set_radius
export(int) var angle_from = 0 setget set_angle_from
export(int) var angle_to = 90 setget set_angle_to
export(int) var width_out = 5 setget set_width_out
export(bool) var right = true setget set_right

#export(bool) var snap setget set_snap
signal enabled_snap

# for debugging
var font

var points_arc
var last = Vector2(0,0)
var first = Vector2(0,0)
var side_pts
var inner_side_pts
var tangs


func _ready():
	#add_to_group("lines", true)
	# signals
	#connect("enabled_snap", self, "on_snap_enabled")
	
	# arc
	points_arc = get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	
	last = points_arc[points_arc.size()-1]
	first = points_arc[0]
	
	# this method does work for 2D because 2D works in pixels, but is not accurate enough for 3D
	side_pts = get_tangs(width_out, true)[0]
	inner_side_pts = get_tangs(width_out, false)[0]
	tangs = get_tangs(width_out, false)[1]
	#tangs = get_tangs(width_out, true)[1]
	
	
	#print(str(first.x) + " " + str(last.x))
	
	# text
	var label = Label.new()
	font = label.get_font("")
	label.free()
	#pass

func _get_item_rect():
	var x = abs(first.x-last.x)+2
	var y = abs(first.y-last.y)+2
	var edge_l = last.x-1
	var edge_b = last.y-1
	if first.x < last.x:
		edge_l = first.x-1
	if first.y < last.y:
		edge_b = first.y-1
		
	return Rect2(Vector2(edge_l, edge_b), Vector2(x,y))


func _draw():
	draw_circle_arc(Vector2(0,0), radius, angle_from, angle_to, Color(0,0,1))
	# debugging
	draw_string(font, last, str(angle_to), Color(1,1,1))
	draw_circle(first, 1, Color(0,1,0))
	draw_circle(last, 1, Color(1,0,0))
	
	# test
	for i in range(side_pts.size()-1):
		draw_line(side_pts[i], side_pts[i+1], Color(0,0,1), 2)
		# debug final point of the side
		draw_circle(side_pts[side_pts.size()-1], 1, Color(1,0,1))
		
		# inside
		draw_line(inner_side_pts[i], inner_side_pts[i+1], Color(0,0,1),2)
		# debug
		draw_circle(inner_side_pts[inner_side_pts.size()-1], 1, Color(0,1,1))
		
		# draw tangs
		#draw_line(points_arc[i], points_arc[i]+tangs[i], Color(1,0,0))
		draw_line(side_pts[i], points_arc[i], Color(1,0,0),1)
		


func draw_circle_arc(center, radius, angle_from, angle_to, color):
	for index in range(points_arc.size()-1):
		draw_line(points_arc[index], points_arc[index+1], color, 2) #4

func get_circle_arc( center, radius, angle_from, angle_to, right):
	var nb_points = 32
	var points_arc = PoolVector2Array()

	for i in range(nb_points+1):
		if right:
			var angle_point = angle_from + i*(angle_to-angle_from)/nb_points - 90
			var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
			points_arc.push_back( point )
		else:
			var angle_point = angle_from - i*(angle_to-angle_from)/nb_points - 90
			var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
			points_arc.push_back( point )
	
	return points_arc
	
func get_tangs(width_out, outer):
	var sides = PoolVector2Array()
	var tangs = PoolVector2Array()
	
	# test side
	for i in range((points_arc.size()-1)):
		#if i < points_arc.size()-1:
		# B-A = a->b
		# some tangents are longer so we need to normalize them
		var tang = (points_arc[i+1]-points_arc[i]).tangent().normalized()
		tangs.push_back(tang)
		
		if outer:
			var point = points_arc[i]+(tang*width_out)
			sides.push_back(point)
		else:
			# symmetric for now
			var point = points_arc[i]-(tang*width_out)
			sides.push_back(point)
		
	print("Special case")
	#print("Last: " + str(points_arc.size()-2))
	#print("2nd to last: " + str(points_arc.size()-3))
	#print("Tangs size: " + str(tangs.size()))
	# final point, special case (we don't have a next point to get tangent from)
	# extrapolate from the previous tangents
	var diff = (tangs[points_arc.size()-3]-tangs[points_arc.size()-2]) 
	var tang = tangs[points_arc.size()-2]-diff
	#var tang = (points_arc[points_arc.size()-1]-points_arc.size()-2).tangent().normalized()
	
	tangs.push_back(tang)
	if outer:
		var point = points_arc[points_arc.size()-1]+(tang*width_out)
		sides.push_back(point)
	else:
		var point = points_arc[points_arc.size()-1]-(tang*width_out)
		sides.push_back(point)
		
		
	return [sides, tangs]
	
func find_closest():
	var closest
	var lowest_dist = 0.0
	var childrens = get_parent().get_parent().get_children()
	var lines = []
	#print(str(childrens))
	for e in childrens:
		for n in e.get_children():
			if ((n.get_name().find("curve") != -1) or (n.get_name().find("straight") != -1)):
				lines.push_back(n)
	
	print(str(lines))
	
	#var lines = get_tree().get_nodes_in_group("lines")
	for i in range (lines.size()-1):
		if lines[i] != self:
			if i < 1:
				lowest_dist = get_global_pos().distance_to(lines[i].get_global_pos())
				closest = lines[i]
			else:
				var new_dist = get_global_pos().distance_to(lines[i].get_global_pos())
				if new_dist < lowest_dist:
					lowest_dist = new_dist
					closest = lines[i]
	
	return [closest, lowest_dist]


func set_radius(val):
	radius = val
	points_arc = get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	last = points_arc[points_arc.size()-1]
	first = points_arc[0]
	#draw_circle_arc(Vector2(0,0), radius, angle_from, angle_to)
	side_pts = get_tangs(width_out, true)[0]
	inner_side_pts = get_tangs(width_out, false)[0]
	tangs = get_tangs(width_out, false)[1]
	#tangs = get_tangs(width_out, true)[1]
	update()
	
func set_angle_from(val):
	angle_from = val
	points_arc = get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	last = points_arc[points_arc.size()-1]
	first = points_arc[0]
	side_pts = get_tangs(width_out, true)[0]
	inner_side_pts = get_tangs(width_out, false)[0]
	tangs = get_tangs(width_out, false)[1]
	#tangs = get_tangs(width_out, true)[1]
	update()
	
func set_angle_to(val):
	angle_to = val
	points_arc = get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	last = points_arc[points_arc.size()-1]
	first = points_arc[0]
	side_pts = get_tangs(width_out, true)[0]
	inner_side_pts = get_tangs(width_out, false)[0]
	tangs = get_tangs(width_out, false)[1]
	#tangs = get_tangs(width_out, true)[1]
	update()

func set_right(val):
	right = val
	points_arc = get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	last = points_arc[points_arc.size()-1]
	first = points_arc[0]
	side_pts = get_tangs(width_out, true)[0]
	inner_side_pts = get_tangs(width_out, false)[0]
	tangs = get_tangs(width_out, false)[1]
	#tangs = get_tangs(width_out, true)[1]
	update()
	
func set_width_out(val):
	width_out = val
	points_arc = get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	last = points_arc[points_arc.size()-1]
	first = points_arc[0]
	side_pts = get_tangs(width_out, true)[0]
	inner_side_pts = get_tangs(width_out, false)[0]
	tangs = get_tangs(width_out, false)[1]
	#tangs = get_tangs(width_out, true)[1]
	
	update()


# snap
#func set_snap(val):
#	snap = val
	#if val:
	#	_on_snap_enabled()
		

func _on_snap_enabled():
	update()
	if get_parent().get_parent() != null:
		var target = find_closest()[0]
		if target != null:
			translate(get_global_transform().xform_inv(target.get_global_pos()))
@tool

extends Node2D

# class member variables go here, for example:
@export var radius: int = 15:
	set(value):
		# TODO: Manually copy the code from this method.
		set_radius(value)
@export var angle_from: int = 0:
	set(value):
		# TODO: Manually copy the code from this method.
		set_angle_from(value)
@export var angle_to: int = 90:
	set(value):
		# TODO: Manually copy the code from this method.
		set_angle_to(value)
@export var width_out: int = 5:
	set(value):
		# TODO: Manually copy the code from this method.
		set_width_out(value)
@export var right: bool = true:
	set(value):
		# TODO: Manually copy the code from this method.
		set_right(value)

#export(bool) var snap:
#	set(value):
#		# TODO: Manually copy the code from this method.
#		set_snap(value)
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
	#connect(&"enabled_snap", self.on_snap_enabled)
	
	# arc
	points_arc = get_node("/root/Geom").get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	
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
	#draw_string(font, last, str(angle_to))
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
	
func get_tangs(width_out, outer):
	var sides = PackedVector2Array()
	var tangs = PackedVector2Array()
	
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
			if ((String(n.get_name()).find("curve") != -1) or (String(n.get_name()).find("straight") != -1)):
				lines.push_back(n)
	
	print(str(lines))
	
	#var lines = get_tree().get_nodes_in_group("lines")
	for i in range (lines.size()-1):
		if lines[i] != self:
			if i < 1:
				lowest_dist = global_position.distance_to(lines[i].global_position)
				closest = lines[i]
			else:
				var new_dist = global_position.distance_to(lines[i].global_position)
				if new_dist < lowest_dist:
					lowest_dist = new_dist
					closest = lines[i]
	
	return [closest, lowest_dist]


func set_radius(val):
	radius = val
	points_arc = get_node("/root/Geom").get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	last = points_arc[points_arc.size()-1]
	first = points_arc[0]
	#draw_circle_arc(Vector2(0,0), radius, angle_from, angle_to)
	side_pts = get_tangs(width_out, true)[0]
	inner_side_pts = get_tangs(width_out, false)[0]
	tangs = get_tangs(width_out, false)[1]
	#tangs = get_tangs(width_out, true)[1]
	queue_redraw()
	
func set_angle_from(val):
	angle_from = val
	points_arc = get_node("/root/Geom").get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	last = points_arc[points_arc.size()-1]
	first = points_arc[0]
	side_pts = get_tangs(width_out, true)[0]
	inner_side_pts = get_tangs(width_out, false)[0]
	tangs = get_tangs(width_out, false)[1]
	#tangs = get_tangs(width_out, true)[1]
	queue_redraw()
	
func set_angle_to(val):
	angle_to = val
	points_arc = get_node("/root/Geom").get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	last = points_arc[points_arc.size()-1]
	first = points_arc[0]
	side_pts = get_tangs(width_out, true)[0]
	inner_side_pts = get_tangs(width_out, false)[0]
	tangs = get_tangs(width_out, false)[1]
	#tangs = get_tangs(width_out, true)[1]
	queue_redraw()

func set_right(val):
	right = val
	points_arc = get_node("/root/Geom").get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	last = points_arc[points_arc.size()-1]
	first = points_arc[0]
	side_pts = get_tangs(width_out, true)[0]
	inner_side_pts = get_tangs(width_out, false)[0]
	tangs = get_tangs(width_out, false)[1]
	#tangs = get_tangs(width_out, true)[1]
	queue_redraw()
	
func set_width_out(val):
	width_out = val
	points_arc = get_node("/root/Geom").get_circle_arc(Vector2(0,0), radius, angle_from, angle_to, right)
	last = points_arc[points_arc.size()-1]
	first = points_arc[0]
	side_pts = get_tangs(width_out, true)[0]
	inner_side_pts = get_tangs(width_out, false)[0]
	tangs = get_tangs(width_out, false)[1]
	#tangs = get_tangs(width_out, true)[1]
	
	queue_redraw()


# snap
#func set_snap(val):
#	snap = val
	#if val:
	#	_on_snap_enabled()
		

func _on_snap_enabled():
	queue_redraw()
	if get_parent().get_parent() != null:
		var target = find_closest()[0]
		if target != null:
			translate(target.global_position * get_global_transform())

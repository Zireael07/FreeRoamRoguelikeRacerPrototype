tool
extends Spatial

# class member variables go here, for example:
var draw
var road_straight
var road

var positions = []

var points_arc = []

func _ready():
	draw = get_node("draw")
	road_straight = preload("res://roads/road_segment_straight.tscn")
	road = preload("res://roads/road_segment.tscn")
	
	# basic stuff
	# assuming 0 is source and 1 is target
	var src_ex = get_src_exit(get_child(0), get_child(1))
	var loc_src_ex = to_local(get_child(0).to_global(src_ex))
	
	var dest_ex = get_dest_exit(get_child(0), get_child(1))
	var loc_dest_ex = to_local(get_child(1).to_global(dest_ex))
	

	print("Line length: " + str(loc_dest_ex.distance_to(loc_src_ex)))

	positions.append(loc_src_ex)
	
	
	var data = calculate(loc_src_ex, loc_dest_ex, src_ex)
	
	road_test(data, loc_src_ex)
	
	#debug drawing
	draw.draw_line(positions)
	
	# Called every time the node is added to the scene.
	# Initialization here
	#pass
	
func calculate(loc_src_ex, loc_dest_ex, src_ex):

	#positions.append(loc_dest_ex)
	
	#B-A: A->B
	# needs to be 2D because 3D doesn't have clamped()
	var line = (Vector2(loc_dest_ex.x, loc_dest_ex.z)-Vector2(loc_src_ex.x, loc_src_ex.z))
	var end_point = Vector2(loc_src_ex.x, loc_src_ex.z) + line.clamped(10)
	
	debug_cube(Vector3(end_point.x, 1, end_point.y))
	
	#B-A: A->B 
	# 3D has no tangent()
	var tang = Vector2(src_ex.x, src_ex.z).tangent()
	var tang2 = (end_point-Vector2(loc_src_ex.x, loc_src_ex.z)).tangent()
	
	# extend them
	var tang_factor = 30
	tang = tang*tang_factor
	tang2 = tang2*tang_factor
	
	# check for intersection (2D only)
	var inters = Geometry.segment_intersects_segment_2d(Vector2(loc_src_ex.x, loc_src_ex.z), Vector2(Vector2(loc_src_ex.x, loc_src_ex.z) - tang), end_point, Vector2(end_point-tang2))
	#print("Intersect: " + str(inters))
	
	debug_cube(Vector3(inters.x, 1, inters.y))
	
	var radius = inters.distance_to(Vector2(loc_src_ex.x, loc_src_ex.z))
	
	# the point to which 0 degrees corresponds
	var angle0 = inters+Vector2(radius,0)
	
	debug_cube(Vector3(angle0.x, 1, angle0.y))
	
	var angles = get_arc_angle(inters, Vector2(loc_src_ex.x, loc_src_ex.z), end_point, angle0)

	var points_arc = get_circle_arc(inters, radius, angles[0], angles[1], true)
	
	# back to 3D
	for i in range(points_arc.size()):
		positions.append(Vector3(points_arc[i].x, 0.01, points_arc[i].y))
	
	positions.append(loc_dest_ex)	

	return [radius, angles[0], angles[1]]
	
func road_test(data, loc_src_ex):
	var radius = data[0]
	var start_angle = data[1]
	var end_angle = data[2]
	
	
	var curved = set_curved_road(radius, start_angle, end_angle)
	curved.set_translation(loc_src_ex)
	
	# place
	if get_child(1).get_translation().y > get_child(0).get_translation().y:
		print("Road in normal direction, positive y")
	else:
		curved.rotate_y(deg2rad(180))
		print("Rotated because we're going back")
	
	# right
	#debug_cube(loc_src_ex + Vector3(tang.x, 1, tang.y))
	#debug_cube(Vector3(end_point.x, 1, end_point.y) + Vector3(tang2.x, 0, tang2.y))
	
	# left
	#debug_cube(loc_src_ex - Vector3(tang.x, 0, tang.y))
	#debug_cube(Vector3(end_point.x, 1, end_point.y) - Vector3(tang2.x, 0, tang2.y))
	
	#positions.append(loc_src_ex - Vector3(tang.x, 0, tang.y))
	
	#positions.append(Vector3(end_point.x, 0, end_point.y))
	#positions.append(Vector3(end_point.x, 1, end_point.y) - Vector3(tang2.x, 0, tang2.y))
	
	
	
	
	
	# place a short straight
	#set_start_straight(get_child(0), get_child(1), loc_src_ex)
	
	
func set_start_straight(src, dest, loc):
	var road_node = road_straight.instance()
	road_node.set_name("Road_instance 0")
	# set length
	road_node.length = 5
	
	var spatial = Spatial.new()
	spatial.set_name("Spatial0")
	add_child(spatial)
	spatial.add_child(road_node)
	
	# place
	if dest.get_translation().y > src.get_translation().y:
		print("Road in normal direction, positive y")
	else:
		spatial.rotate_y(deg2rad(180))
		print("Rotated because we're going back")
		
	
	spatial.set_translation(loc)
		
	
	return road_node	
	
func set_curved_road(radius, start_angle, end_angle):
	var road_node_right = road.instance()
	road_node_right.set_name("Road_instance0")
	#set the angles we wanted
	# road angles are in respect to X axis, so let's subtract 90 to point down Y
	road_node_right.get_child(0).get_child(0).start_angle = start_angle-90
	road_node_right.get_child(0).get_child(0).end_angle = end_angle-90
	#set the radius we wanted
	road_node_right.get_child(0).get_child(0).radius = radius
	add_child(road_node_right)
	return road_node_right


# assume standard rotation for now
func get_src_exit(src, dest):
	if dest.get_translation().x < src.get_translation().x:
		print("X rule")
		return src.point_two
		
	elif dest.get_translation().y > src.get_translation().y:
		print("Y rule")
		return src.point_one
		
	else:
		print("Y rule 2")
		return src.point_three	

# assume standard rotation for now
func get_dest_exit(src, dest):
	if dest.get_translation().x < src.get_translation().x:
		print("X rule")
		return dest.point_one
	
	elif dest.get_translation().y > src.get_translation().y:
		print("Y rule")
		return dest.point_three
		
	else:
		print("Y rule 2")
		return dest.point_one


# debug
func debug_cube(loc):
	var mesh = CubeMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance.new()
	node.set_mesh(mesh)
	node.set_name("Debug")
	add_child(node)
	node.set_translation(loc)


# arc through A and B
func arc(start_point, end_point, height):
	var midpoint = Vector2((end_point.x+start_point.x)/2, (end_point.y+start_point.y)/2)
	
	var width = end_point.distance_to(start_point)
	print("Width" + str(width))
	
	# check for invalid inputs?
	
	
	# B-A = a->b
	var tang = (midpoint-start_point).tangent()
	
	#var height = 5
	
	var arc_top = midpoint + tang.clamped(height)

	
	# https://en.wikipedia.org/wiki/Circular_segment
	var radius = pow(width,2)/(8*height) + height/2	
	print("Radius: " + str(radius))
	
	# this one is wrong for some weird reason
	#center_point = arc_top-tang.clamped(radius)
	
	var center_point = midpoint-tang.clamped((radius-height))
	
	#print("Check" + str(arc_top.distance_to(center_point)))
	
	# the point to which 0 degrees corresponds
	var angle0 = center_point+Vector2(radius,0)
	#print("Angle0" + str(angle0))
	
	var angles = get_arc_angle(center_point, start_point, end_point, angle0)
	
	#var right = true
	#if (angles[1]-angles[0]) > 180:
	#	right = false
		
	#var points_arc = get_circle_arc(center_point, radius, angles[0], angles[1], right)
	
	return [center_point, radius, angles[0], angles[1]] #right]

func get_arc_angle(center_point, start_point, end_point, angle0):
	var angles = []
	
	# angle between line from center point to angle0 and from center point to start point
	var angle = rad2deg((angle0-center_point).angle_to(start_point-center_point))
	
	angles.append(angle)
	print("Angle 1 " + str(angle))
	# equivalent angle for the end point
	angle = rad2deg((angle0-center_point).angle_to(end_point-center_point))
	
	if angle < 0:
		angle = 360+angle
	
	print("Angle 2 " + str(angle))
	angles.append(angle)
	
	print("Arc angle" + str(angles[1]-angles[0]))
	
	return angles




func draw_circle_arc(center, radius, angle_from, angle_to, right, clr):
	var points_arc = get_circle_arc(center, radius, angle_from, angle_to, right)
	#print("Points: " + str(points_arc))
	
	for index in range(points_arc.size()-1):
		draw_line(points_arc[index], points_arc[index+1], clr, 1.5)

	
# from maths
func get_circle_arc( center, radius, angle_from, angle_to, right ):
	var nb_points = 32
	var points_arc = PoolVector2Array()

	for i in range(nb_points+1):
		if right:
			var angle_point = angle_from + i*(angle_to-angle_from)/nb_points #- 90
			var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
			points_arc.push_back( point )
		else:
			var angle_point = angle_from - i*(angle_to-angle_from)/nb_points #- 90
			var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
			points_arc.push_back( point )
	
	return points_arc


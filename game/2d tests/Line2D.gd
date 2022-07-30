@tool
extends Line2D

# class member variables go here, for example:
#var points = []
var prev_points = []
var next_points = []
var vectors = []
var corners = []

var intersections = []

var points_arc = []

var angles = []

var AS
var arc_points = []

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	get_corner_points()
	
	get_intersections()
	
	get_arc_angles()

	get_arc_points() # 32 points per arc
	#print("Arc points: " + str(arc_points))

	setup_astar()
	

func get_corner_points():
	#for i in range(get_polygon().size()):
	#	var point = get_polygon()[i]
	#	points.append(point)
	for i in range(points.size()):
		if i > 0:
			var prev_point = points[i-1]
			
			#print("Prev point " + str(prev_point.x) + ", " + str(prev_point.y))
			prev_points.append(prev_point)
		
		if i < points.size()-1:
			var ahead_point = points[i+1]
			next_points.append(ahead_point)
			
			
	for i in range(points.size()):
		if i > 0:		
			#print("Point " + str(points[i]) + " " + str(prev_points[i-1]))
			# B-A = A-> B
			# we have one less previous point than points
			var vector = points[i]-prev_points[i-1]
			vector = vector.normalized()*5 # 5 units away
			
			vectors.append(vector)
			
			var corner_point = points[i]-vector
			corners.append(corner_point)
			
			#print("Corner point" + str(corner_point))
		
		if i < points.size()-1:
			#print("Point ahead" + str(next_points[i]))
			# B-A = A-> B
			var vector = points[i]-next_points[i]
			#var vector = next_points[i]-points[i]
			vector = vector.normalized()*5
			vectors.append(vector)
			
			var corner_point = points[i]-vector
			corners.append(corner_point)
			
			#print("Corner point" + str(corner_point))
		
		
#		for i in range(corners.size()):
#			print(str(i) + " corner + vector " + str(corners[i]+vectors[i]))


func get_tangent(i,j):
	# calculate because cached vectors sometimes accumulate weird rounding errors
	
	var tang = (points[i]-corners[j]).tangent()
	
#	# B-A = a->b

	#to the right with positive factor
	var tang_factor = -30
	
	
	if j == 0:
		return -tang*tang_factor
	elif j % 2 == 0:
		return -tang*tang_factor
	else:
		return tang*tang_factor

func get_intersection(index):
	#print("Getting intersection for index: " + str(index) + ", -1: " + str(index-1) + " next: " + str(index+1))
	#var start = corners[index]
	var start = corners[index]-get_tangent(index-1,index)
	
	var end = corners[index]+get_tangent(index-1,index)
	
	var start_b = corners[index+1]-get_tangent(index,index+1)
	#var start_b = corners[index+1]
	var end_b = corners[index+1]+get_tangent(index,index+1)
	
	var inters = Geometry.segment_intersects_segment_2d(start, end, start_b, end_b)
	
	intersections.append(inters)
	#print("Appending intersection ... " + str(inters))	

func get_intersections():
	
	get_intersection(1)
	
	if corners.size() > 3:
		get_intersection(3)
		
#	#var start = corners[1]
#	var start = corners[1]-get_tangent(1,1)
#
#	var end = corners[1]+get_tangent(1,1)
#
#	var start_b = corners[2]-get_tangent(1,2)
#	#var start_b = corners[2]
#	var end_b = corners[2]+get_tangent(1,2)
#
#	intersections.append(Geometry.segment_intersects_segment_2d(start, end, start_b, end_b))
	
	
	# used to check corner to corner+tangent
	#intersections.append(Geometry.segment_intersects_segment_2d(corners[1], corners[1]+get_tangent(1,1), corners[2], corners[2]+get_tangent(1,2)))
	
	# now checks corner-tangent to corner+tangent
	#intersections.append(Geometry.segment_intersects_segment_2d(corners[1]-get_tangent(1,1), corners[1]+get_tangent(1,1), corners[2]-get_tangent(1,2), corners[2]+get_tangent(1,2)))

func setup_astar():
	print("Setting up astar...")
	AS = AStar.new()
	
	for i in range(points.size()):
		AS.add_point(i, Vector3(points[i].x, 0, points[i].y))
	# connect first two
	AS.connect_points(0, 1)
	
	#print("Points: " + str(points))
	# this starts at id = points.size()
	var start_id = points.size()
	for i in range(arc_points.size()):
		AS.add_point(start_id+i, Vector3(arc_points[i].x, 0, arc_points[i].y))
	
	# connect endpoint to start of arc
	# flipped
	AS.connect_points(1, points.size()+31)
	
	# connect points.size() +31 ... points.size()
	# 31 because we do i+1
	for i in range(points.size(), points.size()+31):
		AS.connect_points(i, i+1)
	
	# connect the two endpoints of arcs
	AS.connect_points(points.size()+31, points.size()+32)
	
	# connect the other arc
	for i in range(points.size() + 32, points.size() + 32+31):
		AS.connect_points(i, i+1)

	# connect endpoint to second-to-last
	AS.connect_points(points.size()+32+31, 2)

	# connect the last two points	
	AS.connect_points(2,3)

#	# test
	#var path_test_id = 8 #random
	var path_test_id = 2 # end path
	var path_test = AS.get_point_path(0, path_test_id)
	#print(str(path_test))

# -----------------------

func draw_circle_arc(center, radius, angle_from, angle_to, right, clr):
	points_arc = get_node("/root/Geom").get_circle_arc(center, radius, angle_from, angle_to, right)
	
	#draw_circle(points_arc[0], 1.0, Color(1,1,0))
	#print("Angle 0 is " + str(points_arc[0]) + " radius is " + str(radius))
	
	for index in range(points_arc.size()-1):
		draw_line(points_arc[index], points_arc[index+1], clr, 1.5)


func get_arc_angle(corner_id, intersect_id, corner2):
	if intersections.size() + 1 < intersect_id:
		print("Tried getting angle for nonexistent intersection")
		return
		
	# radius = line from intersection to corner point
	var radius = (corners[corner_id]-intersections[intersect_id]).length()
	# the point to which 0 degrees corresponds
	var angle0 = intersections[intersect_id]+Vector2(radius,0)
	
	# angle between line from intersection to angle0 and from intersection to corner id (the lower id one)
	var angle1 = rad2deg((angle0-intersections[intersect_id]).angle_to(corners[corner_id]-intersections[intersect_id]))
	angles.append(angle1)
	print("Angle one: " + str(angle1))
	# equivalent angle for the higher id angle
	var angle2 = rad2deg((angle0-intersections[intersect_id]).angle_to(corners[corner2]-intersections[intersect_id]))
	print("Angle two: " + str(angle2))
	angles.append(angle2)
	
	var arc = angles[0]-angles[1]
	print("Arc is " + str(arc))

	if arc > 200:
		print("Too big arc!")

func get_arc_angles():
	# corner1, intersection, corner2
	get_arc_angle(1,0,2)
	# corner1, intersection, corner2
	get_arc_angle(3,1,4)


func get_arc_points():
	var arc_one = get_node("/root/Geom").get_circle_arc(intersections[0], (corners[1]-intersections[0]).length(), angles[1], angles[1]+(angles[0]-angles[1]), true)
	for i in range(0, arc_one.size()):
		arc_points.append(arc_one[i])
	
	var arc_two = get_node("/root/Geom").get_circle_arc(intersections[1], (corners[3]-intersections[1]).length(), angles[3], angles[3]+(angles[2]-angles[3]), true)
	for i in range(0, arc_two.size()):
		arc_points.append(arc_two[i])
		
func _draw():
	#test
	#draw_line(points[1], vectors[0], Color(0,1,0))
	
	draw_tangents()
	
	if intersections.size() > 0:
		# draw intersection if any
		draw_circle(intersections[0], 1, Color(1,0,1))
		
	if intersections.size() > 1:
		# draw intersection if any
		draw_circle(intersections[1], 1, Color(1,0,1))
	
	
	# test
	#draw_line(intersections[1], intersections[1]+Vector2((corners[3]-intersections[1]).length(), 0), Color(1,0,1), 1.0)
#	draw_line(intersections[1], intersections[1]+(corners[3]-intersections[1]), Color(1,0,1), 1.0)
#	draw_line(intersections[1], intersections[1]+(corners[4]-intersections[1]), Color(1,0,1), 1.0)
	
	
	
	
	# draw arc for point 1 (intersection 0, corners 1 and 2)
	# radius equals distance from intersection to point
	draw_circle_arc(intersections[0], (corners[1]-intersections[0]).length(), angles[1], angles[1]+(angles[0]-angles[1]), true, Color(1,0,1))
	
	draw_circle_arc(intersections[1], (corners[3]-intersections[1]).length(), angles[3], angles[3]+(angles[2]-angles[3]), true, Color(1,0,1))
	
	#draw_corner_line()
	draw_corners()

func draw_tangents():
	draw_line(corners[0], corners[0]+get_tangent(0,0), Color(0,0,1), 1.0)
	
	# test
	draw_line(corners[0], corners[0]-get_tangent(0,0), Color(0,1,0), 1.0)
	
	# corners around point 1
	draw_line(corners[1], corners[1]+get_tangent(0,1), Color(0,0,1), 1.0)
	draw_line(corners[2], corners[2]+get_tangent(1,2), Color(0,0,1), 1.0)
	
	# test
	draw_line(corners[1], corners[1]-get_tangent(0,1), Color(0,1,0), 1.0)
	draw_line(corners[2], corners[2]-get_tangent(1,2), Color(0,1,0), 1.0)
	
	
	# corners around point 2
	draw_line(corners[3], corners[3]+get_tangent(2,3), Color(0,0,1), 1.0)
	draw_line(corners[4], corners[4]+get_tangent(3,4), Color(0,0,1), 1.0)
	
	# test
	draw_line(corners[3], corners[3]-get_tangent(2,3), Color(0,1,0), 1.0)
	draw_line(corners[4], corners[4]-get_tangent(3,4), Color(0,1,0), 1.0)
	
	
	#draw_line(corners[3], corners[3]+get_tangent(2,3), Color(0,0,1), 1.0)
	#draw_line(corners[4], corners[4]+get_tangent(2,4), Color(0,0,1), 1.0)
	
	#draw_line(corners[5], corners[5]+get_tangent(3,5), Color(0,0,1), 1.0)


	
func draw_corner_line():
	for i in range(corners.size()):
		# line between the two
		if i % 2 > 0 and i+1 < corners.size():
			draw_line(corners[i], corners[i+1], Color(0,1,0), 1.0)

func draw_corners():
	for i in range(corners.size()):
		if i % 2 > 0:
			# before
			draw_circle(corners[i], 0.5, Color(0,1,0))
		else:
			# ahead
			draw_circle(corners[i], 0.5, Color(0,0,1))

		
			
		


func draw_vectors():
	for i in range(points.size()):
		if i > 0:
			var j = i-1
			if j <= vectors.size():
			#for j in range(vectors.size()):
			#if i <= vectors.size():
				draw_line(Vector2(0,0), vectors[j], Color(0,1,0))
				#draw_line(get_polygon()[i], vectors[j], Color(0,1,0))

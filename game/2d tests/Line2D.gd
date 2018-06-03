tool
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

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	get_corner_points()
	
	get_intersections()
	
	get_arc_angles()


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
		

func get_intersections():
	
	intersections.append(Geometry.segment_intersects_segment_2d(corners[1], corners[1]+get_tangent(1,1), corners[2], corners[2]+get_tangent(1,2)))
	
	#intersections.append(Geometry.segment_intersects_segment_2d(corners[3], corners[3]+get_tangent(2,3), corners[4], corners[4]+get_tangent(2,4)))
	
	#print("Intersection: " + str(intersections[0]) + "test" + str(intersections[0]+Vector2(4.758389,0)))

func draw_circle_arc(center, radius, angle_from, angle_to, right, clr):
	points_arc = get_circle_arc(center, radius, angle_from, angle_to, right)
	
	#draw_circle(points_arc[0], 1.0, Color(1,1,0))
	#print("Angle 0 is " + str(points_arc[0]) + " radius is " + str(radius))
	
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

func get_arc_angle(corner_id, intersect_id, corner2):
	#if not intersect_id in intersections:
	#	return
		
	# radius = line from intersection to corner point
	var radius = (corners[corner_id]-intersections[intersect_id]).length()
	# the point to which 0 degrees corresponds
	var angle0 = intersections[intersect_id]+Vector2(radius,0)
	
	# angle between line from intersection to angle0 and from intersection to corner id (the lower id one)
	var angle = rad2deg((angle0-intersections[intersect_id]).angle_to(corners[corner_id]-intersections[intersect_id]))
	angles.append(angle)
	print("Angle " + str(angle))
	# equivalent angle for the higher id angle
	angle = rad2deg((angle0-intersections[intersect_id]).angle_to(corners[corner2]-intersections[intersect_id]))
	print("Angle " + str(angle))
	angles.append(angle)
	
	#print("Difference is " + str(angl

	

func get_arc_angles():
	get_arc_angle(1,0,2)
	
	print("Difference is " + str(angles[0]-angles[1]))
	
	#get_arc_angle(3,1,4)
	
	#print("Difference is " + str(angles[2]-angles[3]))
		
	#pass

		
func _draw():
	#test
	#draw_line(points[1], vectors[0], Color(0,1,0))
	
	draw_tangents()
	
	# draw intersection if any
	draw_circle(intersections[0], 1, Color(1,0,1))
	
	
	# test
	#draw_line(intersections[1], intersections[1]+Vector2((corners[3]-intersections[1]).length(), 0), Color(1,0,1), 1.0)
#	draw_line(intersections[1], intersections[1]+(corners[3]-intersections[1]), Color(1,0,1), 1.0)
#	draw_line(intersections[1], intersections[1]+(corners[4]-intersections[1]), Color(1,0,1), 1.0)
	
	
	
	
	# draw arc for point 1 (intersection 0, corners 1 and 2)
	# radius equals distance from intersection to point
	draw_circle_arc(intersections[0], (corners[1]-intersections[0]).length(), angles[1], angles[1]+(angles[0]-angles[1]), true, Color(1,0,1))
	
#	draw_circle_arc(intersections[1], (corners[3]-intersections[1]).length(), angles[2], angles[2]+(angles[2]-angles[3]), false, Color(1,0,1))
	
	#draw_corner_line()
	draw_corners()

func draw_tangents():
	draw_line(corners[0], corners[0]+get_tangent(0,0), Color(0,0,1), 1.0)
	
	# corners around point 1
	draw_line(corners[1], corners[1]+get_tangent(1,1), Color(0,0,1), 1.0)
	draw_line(corners[2], corners[2]+get_tangent(1,2), Color(0,0,1), 1.0)
	
	# corners around point 2
	draw_line(corners[3], corners[3]+get_tangent(2,3), Color(0,0,1), 1.0)
	draw_line(corners[4], corners[4]+get_tangent(2,4), Color(0,0,1), 1.0)
	
	draw_line(corners[5], corners[5]+get_tangent(3,5), Color(0,0,1), 1.0)


	
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

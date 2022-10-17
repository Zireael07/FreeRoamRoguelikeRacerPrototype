@tool
extends Node

# NOTE: p1, p2, p3 are relative to origin and p3 is between p1 and p2
# NOTE: breaks if origin is too far away from the three points
func make_arc_from_points(p1, p2, p3, origin):
	# test
	#var ccw = is_arc_clockwise(p1, p3, p2)
	#print("Arc clockwise? - ", ccw)
	
	# arc from 3 points
	# https://stackoverflow.com/a/53318286
	# a = p1, b = p3, c = p2; s1, s2 = m1, m2
	var d1 = Vector2(p3.y-p1.y, p1.x-p3.x)
	var d2 = Vector2(p2.y-p1.y, p1.x-p2.x)
	var k = d2.x * d1.y - d2.y * d1.x
	
	# paranoia
	if k == 0:
		return []
	
	# midpoints of two chords
	var m1 = (p3+p1)/2
	var m2 = (p2+p1)/2
	
	var l = d1.x * (m2.y - m1.y) - d1.y * (m2.x - m1.x)
	# slope of something?
	var m = l / k
	var center = Vector2(m2.x + m * d2.x, m2.y + m * d2.y)
	
	var radius = center.distance_to(p1)
	#var dx = center.x - a.x
	#var dy = center.y - a.y
	#let radius = sqrt(dx * dx + dy * dy)
	
	# print("radius: ", radius, ", center: ", center)
	
	#var p4_loc = Vector2(0,0).distance_to(p4)
	
	# sagitta (the height of the arc, or how much it "bulges")
#	var s_len = (p4-p3).length()
#
#	# paranoia!
#	if s_len == 0:
#		s_len = 0.01
#
#	print(" right: ", ccw, " : p1 (car) ", p1, " p2 ", p2, " p4 ", p4, " s len ", s_len)
#
#	# ref: https://www.afralisp.net/archive/lisp/Bulges1.htm
#	# sagitta is always perpendicular to p1-p2
#	#B-A: A->B 
#	var half = p4-p1
#	var perp = p4 + half.tangent() # perpendicular vector
#	var n = (perp-p4).normalized() # unit vector
#	#print("unit vec: ", n)
#
#	#var s_end = p4-n*s_len #P3
#	#debug_cube(to_local(closest.get_global_transform().origin+Vector3(s_end.x, 0.01, s_end.y)), true)
#	#print("Sagitta endpoint: ", s_end)
#
#	# sagitta (p3-p4) forms a right triangle with either of p1-p4 or p2-p4 (half of chord)
#	# so tan(angle at p1 or p2) = sagitta divided by either p1-p4 or p2-p4
#	# hence atan sagitta / p1-p4 is the angle epsilon 
#
#	# tangent of epsilon (epsilon is the arc angle divided by 4)
#	#var ta = s/(p4-p1)
#	var half_len = half.length()
#	#var eps = atan(s_len/half_len)
#	# half of chord^2+sagitta^2 divided by 2*sagitta
#	#var radius = (pow(half_len, 2)+pow(s_len,2))/2*s_len
#
#	# radius = h + s_len AND C p4 p2 is a right triangle
#	#https://math.stackexchange.com/a/491816
#	# h=u, t is half_len, b is sagitta length
#	var h = (pow(half_len,2) - pow(s_len,2))/(2*s_len)
#
#	#https://math.stackexchange.com/a/87374
#	#var h = sqrt(pow(radius,2) - pow(half_len*2, 2)/4)
#
#	# radius from sagitta and chord
#	# https://math.stackexchange.com/a/2135602
#	# radius = s_len/2+chord^2/2*s_len
#	#var radius = s_len/2+pow(half_len*2,2)/(2*s_len)
#	#var h = radius - s_len
#
#	#if h < 0:
#	#	print("Error!")
#
#	var radius = h + s_len	
	#print("h: ", h, " radius ", radius, " s ", s_len)

	# now we can finally find the center
	#var center = p4+h*n
	
	var gloc_c = origin + Vector3(center.x, 0.01, center.y)
	#debug_cube(to_local(gloc_c), "flip")
	#print("Center: ", center)

	# the point to which 0 degrees corresponds
	var angle0 = center+Vector2(radius,0)
	#print("Angle0: ", angle0)
	#debug_cube(to_local(origin + Vector3(angle0.x, 0.01, angle0.y)), "flip")
	
	#print("Center: ", center, " angle0 ", angle0)
	
	# get two angles/arcs
	var angles = get_arc_angle(center, p1, p3, angle0)
	var points_arc1 = get_circle_arc(center, radius, angles[0], angles[1], true, 16)
	
	angles = get_arc_angle(center, p3, p2, angle0)
	var points_arc2 = get_circle_arc(center, radius, angles[0], angles[1], true, 16)
	
	var points_arc = points_arc1 + points_arc2
	
	# debug
	#print("Intersection arc for inters: ", closest.get_global_transform().origin)
	
	var arcs = []
	for i in range(points_arc.size()):
		var gloc = Vector3(points_arc[i].x, 0.01, points_arc[i].y)+origin
		arcs.append(gloc)
		#debug_cube(to_local(gloc), "left_flip")
	
	
	#var midpoint = Vector3(points_arc[16].x, 0.01, points_arc[16].x)
	#var pos = closest.get_global_transform().origin+midpoint
		
	return arcs

# https://stackoverflow.com/a/63566113
func is_arc_clockwise(p1, p2, p3):
	var se = p3-p2
	var sm = p1-p2
	var cp = se.cross(sm)
	return cp > 0
	
	
# calculated arc is in respect to X axis
func get_arc_angle(center_point, start_point, end_point, angle0, verbose=false):
	var angles = []
	
	# angle between line from center point to angle0 and from center point to start point
	var angle1 = rad_to_deg((angle0-center_point).angle_to(start_point-center_point))
	
	if angle1 < 0:
		angle1 = 360.0+angle1
		#print("Angle 1 " + str(angle))
	
	#angles.append(angle)
	#Logger.mapgen_print("Angle 1 " + str(angle1))
	# equivalent angle for the end point
	var angle2 = rad_to_deg((angle0-center_point).angle_to(end_point-center_point))
	
	if angle2 < 0:
		angle2 = 360.0+angle2
		#print("Angle 2 " + str(angle))
	
	#Logger.mapgen_print("Angle 1 " + str(angle1) + ", angle 2 " + str(angle2))
	#angles.append(angle)
	
	var arc = angle1-angle2
	
	if verbose:
		print("Angle 1 " + str(angle1) + ", angle 2 " + str(angle2) + " = arc angle " + str(arc))
		
	if arc > 190:
		if verbose:
			print("Too big arc " + str(angle1) + " , " + str(angle2))
		angle2 = angle2+360.0
	if arc < -190:
		if verbose:
			print("Too big arc " + str(angle1) + " , " + str(angle2))
		angle1 = angle1+360.0
		
	angles = [angle1, angle2]
	
	return angles

# https://www.xarg.org/2010/06/is-an-angle-between-two-other-angles/
func is_angle_between(n, start, end):
	# % is only for integers
	n = int(n)
	start = int(start)
	end = int(end)
	print("Checking: is n: ", n, " between: s: ", start, " e: ", end)
	# normalize the angles (two ways to do so)
	n = (360 + (n % 360)) % 360;
	start = (3600000 + start) % 360;
	end = (3600000 + end) % 360;

	# swap
	if start > end:
		# needs a tmp otherwise doesn't work
		var tmp = start
		start = end
		end = tmp
		
	# doesn't work for my tests
	#var res = start <= n || n <= end
	
	print("Start: ", start, "end: ", end)
	
	#if (start < end):
	var res = start <= n && n <= end
	
	print("Result: ", res)
	return res


# from maths
func get_circle_arc( center, radius, angle_from, angle_to, right, nb_points=32):
	#var nb_points = 32
	var points_arc = PackedVector2Array()

	for i in range(nb_points+1):
		if right:
			var angle_point = angle_from + i*(angle_to-angle_from)/nb_points #- 90
			var point = center + Vector2( cos(deg_to_rad(angle_point)), sin(deg_to_rad(angle_point)) ) * radius
			points_arc.push_back( point )
		else:
			var angle_point = angle_from - i*(angle_to-angle_from)/nb_points #- 90
			var point = center + Vector2( cos(deg_to_rad(angle_point)), sin(deg_to_rad(angle_point)) ) * radius
			points_arc.push_back( point )
	
	return points_arc

@tool
extends Node2D

# class member variables go here, for example:
@export var start_point: Vector2 = Vector2(0,0)
@export var end_point: Vector2 = Vector2(0,0)
@export var height: int = 5
#export(int) var radius = 15

# helpers (A LOT)
var midpoint = Vector2(0,0)
var tang = Vector2(0,0)
var arc_top = Vector2(0,0)
var radius = 0
var center_point = Vector2(0,0)
var angle0 = Vector2(0,0)
var angles = []
@export var right: bool = true

# result
var points_arc = []


func _ready():
	
	midpoint = Vector2((end_point.x+start_point.x)/2, (end_point.y+start_point.y)/2)
	
	var width = end_point.distance_to(start_point)
	print("Width" + str(width))
	
	# check for invalid inputs?
	
	
	
	# B-A = a->b
	var tang = (midpoint-start_point).tangent()
	
	arc_top = midpoint + tang.clamped(height)

	
	# https://en.wikipedia.org/wiki/Circular_segment
	radius = pow(width,2)/(8*height) + height/2	
	print("Radius: " + str(radius))
	
	# this one is wrong for some weird reason
	#center_point = arc_top-tang.clamped(radius)
	
	center_point = midpoint-tang.clamped((radius-height))
	
	#print("Check" + str(arc_top.distance_to(center_point)))
	
	# the point to which 0 degrees corresponds
	angle0 = center_point+Vector2(radius,0)
	#print("Angle0" + str(angle0))
	
	angles = get_arc_angle(center_point, start_point, end_point)
	
#	right = true
#	if (angles[1]-angles[0]) > 180:
#		right = false
	

func _draw():
	draw_line(start_point, end_point, Color(0,1,0), 1.0)
	
	#draw_line(start_point, arc_top, Color(0,0,1), 1.0)
	#draw_line(arc_top, end_point, Color(0,0,1), 1.0)
	
	draw_circle(midpoint, 1.0, Color(0,1,0))
	draw_circle(arc_top, 1.0, Color(1,0,0))
	draw_circle(angle0, 1.0, Color(0,0,1))
	draw_circle(center_point, 1.0, Color(0,0,1))

	# test
	draw_line(arc_top, center_point, Color(0,0,1), 1.0)	
	draw_circle_arc(center_point, radius, angles[0], angles[1], right, Color(1,0,0))


func get_arc_angle(center_point, start_point, end_point):
	var angles = []
	
	# angle between line from center point to angle0 and from center point to start point
	var angle = rad2deg((angle0-center_point).angle_to(start_point-center_point))
	
	angles.append(angle)
	print("Angle " + str(angle))
	# equivalent angle for the end point
	angle = rad2deg((angle0-center_point).angle_to(end_point-center_point))
	print("Angle " + str(angle))
	angles.append(angle)
	
	print("Arc angle" + str(angles[1]-angles[0]))
	
	return angles

func draw_circle_arc(center, radius, angle_from, angle_to, right, clr):
	points_arc = get_node("/root/Geom").get_circle_arc(center, radius, angle_from, angle_to, right)
	#print("Points: " + str(points_arc))
	
	for index in range(points_arc.size()-1):
		draw_line(points_arc[index], points_arc[index+1], clr, 1.5)

tool
extends Node2D

# class member variables go here, for example:
	
	
# need to be class-level because draw()
var loc_src_exit = Vector2(0,0)
var loc_dest_exit = Vector2(0,0)

var loc_src_extended = Vector2(0,0)
var loc_dest_extended = Vector2(0,0)

var helper_line

func _ready():
	helper_line = load("res://2d tests/Line2D.tscn")
	
	# basic stuff
	# assuming 0 is source and 1 is target
	var src_exit = get_src_exit(get_child(0), get_child(1))
	loc_src_exit = to_local(get_child(0).to_global(src_exit))
	
	var dest_exit = get_dest_exit(get_child(0), get_child(1))
	loc_dest_exit = to_local(get_child(1).to_global(dest_exit))
	
	extend_lines()
	
	setup_line_2d()
	

func extend_lines():
	#B-A: A->B
	var src_line = loc_src_exit-get_child(0).get_position()
	var extend = 2
	loc_src_extended = src_line*extend + get_child(0).get_position()
	
	var dest_line = loc_dest_exit-get_child(1).get_position()
	
	loc_dest_extended = dest_line*extend + get_child(1).get_position()

func setup_line_2d():
	var help = helper_line.instance()
	
	help.points = [loc_src_exit, loc_src_extended, loc_dest_extended, loc_dest_exit]
	# looks
	help.width = 5
	help.set_default_color(Color(0.4, 0.5, 1, 0.2))
	
	add_child(help)



func _draw():
	draw_line(loc_src_exit, loc_dest_exit, Color(0,1,0, 0.5))

	# test
	#draw_line(get_child(0).get_position(), loc_src_exit, Color(0,0,1))

	draw_circle(loc_src_extended, 1.0, Color(0,0,1))
	draw_circle(loc_dest_extended, 1.0, Color(0,1,0))
	
	draw_line(loc_src_exit, loc_src_extended, Color(0,0,1))
	draw_line(loc_src_extended, loc_dest_extended, Color(0,0,1))
	draw_line(loc_dest_extended, loc_dest_exit, Color(0,0,1))
	
	#var arr = [loc_src_exit, loc_src_extended, loc_dest_extended, loc_dest_exit]
	#draw_polyline(arr, Color(0,0,1))

# assume standard rotation for now
func get_src_exit(src, dest):
	if dest.get_position().x < src.get_position().x:
		print("X rule")
		return src.point_two
		
	elif dest.get_position().y > src.get_position().y:
		print("Y rule")
		return src.point_one
		
	else:
		print("Y rule 2")
		return src.point_three	

# assume standard rotation for now
func get_dest_exit(src, dest):
	if dest.get_position().x < src.get_position().x:
		print("X rule")
		return dest.point_one
	
	elif dest.get_position().y > src.get_position().y:
		print("Y rule")
		return dest.point_three
		
	else:
		print("Y rule 2")
		return dest.point_one

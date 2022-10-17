@tool
extends ImmediateMesh

# class member variables go here, for example:
var m = StandardMaterial3D.new()
var points = PackedVector3Array()
@export var color: Color = Color(1,1,1)


func _ready():
	#Turn off shadows
	self.set_cast_shadows_setting(0)
	
	#set_material()
	

func set_material():
	m.set_line_width(3)
	m.set_point_size(3)
	m.set_flag(StandardMaterial3D.FLAG_UNSHADED, true)
	m.set_flag(StandardMaterial3D.FLAG_USE_POINT_SIZE, true)
	
	m.set_albedo(color)
	
	#m.set_fixed_flag(FixedMaterial.FLAG_USE_COLOR_ARRAY, true)
	
	surface_set_material(0, m)

func set_material_color(color):	
	m.set_line_width(3)
	m.set_point_size(3)
	m.set_flag(StandardMaterial3D.FLAG_UNSHADED, true)
	m.set_flag(StandardMaterial3D.FLAG_USE_POINT_SIZE, true)
	
	m.set_albedo(color)
	
	surface_set_material(0, m)



func draw_line(points):
	set_material()


	surface_begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	for i in points:
		surface_add_vertex(i)
	surface_end()
	
	pass

func draw_line_color(points, size, color_par):
	#set_material_color(color)	
	
	clear_surfaces()
	
	color = color_par
	set_material()
	
	if (size != null):
		##set width
		m.set_line_width(size)
		m.set_point_size(size)
	
	surface_begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	for i in points:
		#set_color(color)
		surface_add_vertex(i)
	surface_end()	

func get_circle_arc_poly(center, radius, angle_from, angle_to):
	# from 3d to 2d
	center = Vector2(center.x, center.z)
	# usual arc stuff
	var nb_points = 32
	var points_arc = PackedVector2Array()
	points_arc.push_back(center)
	var colors = PackedColorArray([color])

	for i in range(nb_points+1):
		var angle_point = angle_from + i*(angle_to-angle_from)/nb_points
		points_arc.push_back(center + Vector2( cos( deg_to_rad(angle_point) ), sin( deg_to_rad(angle_point) ) ) * radius)
	
	# to 3D
	var points_arc_3d = PackedVector3Array()
	
	for p in points_arc:
		points_arc_3d.push_back(Vector3(p.x, 1, p.y))
	
	# end once again
	points_arc_3d.push_back(Vector3(center.x, 1, center.y))
	
	return points_arc_3d
	
func draw_arc_poly(center, rot, angle, color_par):
	var points = []
	clear_surfaces()
	
	color = color_par
	set_material()
	
	points = get_circle_arc_poly(center, 2, rot, rot+angle)
	
	#begin(Mesh.PRIMITIVE_TRIANGLES,null)
	surface_begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	for i in points:
		surface_add_vertex(i)
	surface_end()

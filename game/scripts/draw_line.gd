tool
extends GeometryInstance

# class member variables go here, for example:
var m = SpatialMaterial.new()
var points = PoolVector3Array()
export(Color) var color = Color(1,1,1)


func _ready():
	#Turn off shadows
	self.set_cast_shadows_setting(0)
	
	#set_material()
	

func set_material():
	m.set_line_width(3)
	m.set_point_size(3)
	m.set_flag(SpatialMaterial.FLAG_UNSHADED, true)
	m.set_flag(SpatialMaterial.FLAG_USE_POINT_SIZE, true)
	
	m.set_albedo(color)
	
	#m.set_fixed_flag(FixedMaterial.FLAG_USE_COLOR_ARRAY, true)
	
	set_material_override(m)

func set_material_color(color):	
	m.set_line_width(3)
	m.set_point_size(3)
	m.set_flag(SpatialMaterial.FLAG_UNSHADED, true)
	m.set_flag(SpatialMaterial.FLAG_USE_POINT_SIZE, true)
	
	m.set_albedo(color)
	
	set_material_override(m)



func draw_line(points):
	set_material()


	begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	for i in points:
		add_vertex(i)
	end()
	
	pass

func draw_line_color(points, size, color_par):
	#set_material_color(color)	
	
	clear()
	
	color = color_par
	set_material()
	
	if (size != null):
		##set width
		m.set_line_width(size)
		m.set_point_size(size)
	
	begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	for i in points:
		#set_color(color)
		add_vertex(i)
	end()	

func get_circle_arc_poly(center, radius, angle_from, angle_to):
	# from 3d to 2d
	center = Vector2(center.x, center.z)
	# usual arc stuff
	var nb_points = 32
	var points_arc = PoolVector2Array()
	points_arc.push_back(center)
	var colors = PoolColorArray([color])

	for i in range(nb_points+1):
		var angle_point = angle_from + i*(angle_to-angle_from)/nb_points
		points_arc.push_back(center + Vector2( cos( deg2rad(angle_point) ), sin( deg2rad(angle_point) ) ) * radius)
	
	# to 3D
	var points_arc_3d = PoolVector3Array()
	
	for p in points_arc:
		points_arc_3d.push_back(Vector3(p.x, 1, p.y))
	
	# end once again
	points_arc_3d.push_back(Vector3(center.x, 1, center.y))
	
	return points_arc_3d
	
func draw_arc_poly(center, rot, angle, color_par):
	var points = []
	clear()
	
	color = color_par
	set_material()
	
	points = get_circle_arc_poly(center, 2, rot, rot+angle)
	
	#begin(Mesh.PRIMITIVE_TRIANGLES,null)
	begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	for i in points:
		add_vertex(i)
	end()

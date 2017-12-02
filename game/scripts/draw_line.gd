tool
extends GeometryInstance

# class member variables go here, for example:
var m = SpatialMaterial.new()
var points = PoolVector3Array()
export(Color) var color = Color(1,1,1)


func _ready():
	set_material()
	

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

	begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	for i in points:
		add_vertex(i)
	end()
	
	pass

func draw_line_color(points, size, color):
	set_material_color(color)	
	
	clear()
	
	if (size != null):
		##set width
		m.set_line_width(size)
		m.set_point_size(size)
	
	begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	for i in points:
		add_vertex(i)
	end()	

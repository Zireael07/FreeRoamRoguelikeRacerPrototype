tool
extends GeometryInstance

# class member variables go here, for example:
var m = FixedMaterial.new()
var points = Vector3Array()

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	m.set_line_width(3)
	m.set_point_size(3)
	m.set_fixed_flag(FixedMaterial.FLAG_USE_POINT_SIZE, true)
	m.set_flag(Material.FLAG_UNSHADED, true)
	
	set_material_override(m)


func draw_line(points):

	begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	for i in points:
		add_vertex(i)
	end()
	
	pass

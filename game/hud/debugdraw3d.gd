# based on kidscancode's
extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

class Vector:
	var object
	var vector
	var scale
	var width
	var color
	func _init(o, v, s, w, c):
		object = o
		vector = v
		scale = s
		width = w
		color = c
	func draw(node, cam):
		# paranoia
		if object == null:
			return
		if cam.is_position_behind(object.global_transform.origin):
			return
		var start = cam.unproject_position(object.global_transform.origin)
		var end = cam.unproject_position(object.global_transform.origin + vector * scale)
		node.draw_line(start, end, color, width)
		node.draw_triangle(end, start.direction_to(end), width*2, color)

class Line:
	var start
	var end
	var width
	var color
	var arrow

	func _init(s, e, w, c, a=true):
		start = s
		end = e
		width = w
		color = c
		arrow = a
		
	func draw(node, cam):
		if cam.is_position_behind(start) or cam.is_position_behind(end):
			return
		var s = cam.unproject_position(start)
		var e = cam.unproject_position(end)
		node.draw_line(s, e, color, width)
		if arrow:
			node.draw_triangle(e, (e-s).normalized(), width*2, color)

			
var vectors = []
var lines = {}

func _process(_delta):
	if not visible:
		return
	update()

func _draw():
	var camera = get_viewport().get_camera()
	
	if camera.get_name() != "CameraDebug":
		return
	
	for vector in vectors:
		vector.draw(self, camera)
	for object in lines:
		for line in lines[object]:
			line.draw(self, camera)

func clear_lines(object):
	lines[object] = []
	
func add_line(object, start, end, width, color):
	if not lines.has(object):
		lines[object] = []
	lines[object].append(Line.new(start, end, width, color))

# hack Zir
func update_line(object, id, start, end):
	if lines.has(object):
		var line = lines[object][id]
		line.start = start
		line.end = end

func add_vector(object, vector, size, width, color):
	vectors.append(Vector.new(object, vector, size, width, color))
	
# see above
func update_vector(id, vector, color=false):
	var vec = vectors[id]
	vec.vector = vector
	if color:
		vec.color = color

func draw_triangle(pos, dir, size, color):
	var a = pos + dir * size
	var b = pos + dir.rotated(2*PI/3) * size
	var c = pos + dir.rotated(4*PI/3) * size
	var points = PoolVector2Array([a, b, c])
	if !points.empty():
		draw_polygon(points, PoolColorArray([color]))

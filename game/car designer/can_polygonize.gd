@tool
extends Polygon2D

# Declare member variables here. Examples:
var poly = []
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_name() == "reartest":
		poly.resize(0)
		poly = get_polygon()
		# split 4-5 edge to get proper number of points for a wheel well
		var tmp = (poly[5]+poly[4])/2 # midpoint
		poly.insert(5, tmp)
	
		# split final edge to avoid problems polygonizing when windows are involved
		tmp = (poly[0]+poly[poly.size()-1])/2 # midpoint
		poly.append(tmp)
	
		set_polygon(poly)
		
		
	# we don't have to triangulate a 2D polygon drawn by hand in editor, since if it draws it can be triangulated
	#var indices = Array(Geometry.triangulate_polygon(PackedVector2Array(get_polygon())))
	#print(str(indices))

	# add window
	var fin = []
	# because PackedVector2Array doesn't have duplicate
	fin = Array(get_polygon()).duplicate()	
	if get_name() == "reartest":
		# because the final point is the midpoint
		var i = fin.size()-2
		# top right, bottom right
		var window_rear = [Vector2(1440-600, 130), Vector2(1450-600, 230)]
		for p in window_rear:
			fin.insert(i, p)
	elif get_name() == "fronttest":
		var front_wheel_end = 7
		# bottom left, top left
		var window_front = [Vector2(60, 260), Vector2(60, 200)]
		for p in window_front:
			fin.insert(front_wheel_end+1, p)
	elif get_name() == "bottomtest":
		# replace dummy values with window bottom
		var window_bottom = [Vector2(1450-600, 230), Vector2(60, 260)]
		fin[2] = window_bottom[0]
		fin[3] = window_bottom[1]
	
	elif get_name() == "toptest":
		# replace dummy values with window top
		var window_top = [Vector2(60, 200), Vector2(1440-600, 130)]
		fin[0] = window_top[0]
		fin[1] = window_top[1] 
	
	var indices = Array(Geometry.triangulate_polygon(PackedVector2Array(fin)))
	#print(str(indices))	
	print(str((indices.size() > 0)))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

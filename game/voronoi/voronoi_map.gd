tool
extends "voronoi3d.gd"

# class member variables go here, for example:
var road_straight
var mult = 10
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	road_straight = preload("res://roads/road_segment_straight.tscn")
	
	
	spawn_cubes(commons)
	
	spawn_roads(lines)
	
	#spawn_cubes_line(lines[0])
	#spawn_road(lines[0])
	

func spawn_cubes(common):
	#print("Common" + str(common))
	for c in common:
		for p in c:
			debug_cube(Vector3(p[0].x*mult, 2, p[0].y*mult))

func spawn_cubes_line(line):
	for l in line:
		debug_cube(Vector3(l.x*mult, 0, l.y*mult))


func debug_cube(loc):
	var mesh = CubeMesh.new()
	mesh.set_size(Vector3(1,1,1))
	var node = MeshInstance.new()
	node.set_mesh(mesh)
	add_child(node)
	node.set_translation(loc)

func spawn_road(line):
	print("Spawning road for line: " + str(line))
	var dist = line[0].distance_to(line[1])
	var long = dist / 2 * mult # road section length
	#print("Calculated road length: " + str(long))
	#print("Spawning road, distance " + str(dist))
	if dist > 6 and long > 0:
		print("Instance road")
		var road = road_straight.instance()
		#var ang = line[0].angle_to(line[1])
		var rel = line[1]-line[0]
		var ang = atan2(rel.x, rel.y)
		#print("Angle " + str(ang))
		road.length = long
		add_child(road)
		road.set_translation(Vector3(line[0].x*mult, 0, line[0].y*mult))
		road.set_rotation(Vector3(0, ang, 0))




func spawn_roads(lines):
	for l in lines:
		#print("Instance road")
		#var road = road_straight.instance()
		#add_child(road)
		#road.set_translation(Vector3(l[0].x, 0, l[0].y))
		
		spawn_road(l)
			
			

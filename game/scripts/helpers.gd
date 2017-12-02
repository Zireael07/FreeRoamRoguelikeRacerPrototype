extends "mesh_gen.gd"

# class member variables go here, for example:

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

##MATH
func get_circle_arc_simple(center, radius, angle):
	var nb_points = 32
	var points_arc = PoolVector2Array()
	
	var angle_from = 90-angle/2
	var angle_to = 90+angle/2
	
	for i in range(nb_points+1):
		var angle_point = angle_from + i*(angle_to-angle_from)/nb_points - 90
		var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
		points_arc.push_back( point )
	
	return points_arc


func get_circle_arc( center, radius, angle_from, angle_to, right ):
	var nb_points = 32
	var points_arc = PoolVector2Array()

	for i in range(nb_points+1):
		if right:
			var angle_point = angle_from + i*(angle_to-angle_from)/nb_points - 90
			var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
			points_arc.push_back( point )
		else:
			var angle_point = angle_from - i*(angle_to-angle_from)/nb_points - 90
			var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
			points_arc.push_back( point )
	
	return points_arc
	
##MESHES
#inherited	
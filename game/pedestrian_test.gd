extends Node3D #PhysicsBody3D #AnimatableBody3D

var index = 0
var road = null
var total_dist = null

# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.connect("mapgen_done", setup)

func setup():
	# place on the road
	road = get_node("/root/Node3D/map/Road 4-1").get_node(^"Spatial0/Road_instance 0")
	var gl_pos = road.to_global(road.right_positions[0]) + Vector3(1,1,0)
	global_position = gl_pos
	
	total_dist = (road.right_positions[road.right_positions.size()-1]-road.right_positions[0]).length() 
	#print("Total dist: ", total_dist)
	
	var tween = get_tree().create_tween()
	# avg walking speed is somewhere between 1,5-2 m/s
	tween.tween_property(self, "index", road.right_positions.size()-1, total_dist*2)
	tween.play()

func move(index):
	#index = lerp(0, road.sidewalk_right.size()-1, total_dist*2*delta)
	global_position = road.to_global(road.right_positions[index]+ Vector3(1,1,0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print("Index: ", index)
	# doesn't work on ints :(
	#index = lerpf(0.0, float(road.sidewalk_right.size()-1), (total_dist*2*delta)/delta)
	global_position = road.to_global(road.right_positions[index]+ Vector3(1,1,0))
	#move(index)
	pass

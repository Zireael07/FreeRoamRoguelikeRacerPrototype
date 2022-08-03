extends Node3D

var memory = []

# testing
@export var num_rays = 16
@export var look_side = 3.0
var look_ahead = 15.0

var rays = [] 
var forward_ray = null
# Called when the node enters the scene tree for the first time.
func _ready():
	rays.resize(num_rays)
	add_rays(get_parent())
	
func add_rays(body):
	var angle = 2 * PI / num_rays
	for i in num_rays:
		var r = RayCast3D.new()
		get_parent().get_node("ContextRays").add_child(r)
		# TODO: base on polar angle?
		# TODO: make speed dependent
		if i == 0 or i == 1 or i == num_rays-1:
			r.target_position = Vector3.FORWARD * look_ahead
		elif i == 2 or i == num_rays-2:
			r.target_position = Vector3.FORWARD * (look_ahead-2)
		else:
			r.target_position = Vector3.FORWARD * look_side
		r.rotation.y = -angle * i
		r.add_exception(body)
		r.enabled = true
		# debug
		#rays[i] = (r.target_position.normalized()*4).rotated(Vector3(0,1,0), r.rotation.y)
		rays[i] = (r.target_position).rotated(Vector3(0,1,0), r.rotation.y)
		if i == num_rays-(num_rays/4): #numrays/4 is 90 degrees to the right, numrays-(x/4) is to the left
			r.debug_shape_custom_color = Color(0.99, 0.99, 0.90)
	forward_ray = get_parent().get_node("ContextRays").get_child(0)

func update_memory():
	var cur = Time.get_ticks_usec()
	# if we detect something, store it
	for i in range(num_rays):
		var ray = get_parent().get_node("ContextRays").get_child(i)
		if ray.is_colliding():
			var gl = ray.get_collision_point() # in global coords
			#var t = Time.get_ticks_usec()
			memory.append([gl, cur])
	
	var to_rem = []
	for i in range(memory.size()-1):
		var p = memory[i]
		var d = get_parent().global_transform.origin.distance_to(p[0])
		if d > look_ahead:
			to_rem.append(i)
		# memory sticks around for 5s
		if cur > p[1]+50.0:
			to_rem.append(i)

	for i in to_rem:
		memory.remove_at(i)

func _on_timer_timeout():
	update_memory()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

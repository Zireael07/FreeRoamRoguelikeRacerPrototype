
extends Camera

# Member variables
var collision_exception = []
export var min_distance = 0.5
export var max_distance = 4.0
export var angle_v_adjust = 0.0
export var autoturn_ray_aperture = 25
export var autoturn_speed = 50
var max_height = 2.0
var min_height = 0

var debug
#set at ready
var origin
var target_orig

func _physics_process(dt):
	if (not debug):
		var target = get_parent().get_global_transform().origin
		var pos = get_global_transform().origin
		var up = Vector3(0, 1, 0)
		
		var delta = pos - target
		
		# Regular delta follow
		
		# Check ranges
		if (delta.length() < min_distance):
			delta = delta.normalized()*min_distance
		elif (delta.length() > max_distance):
			delta = delta.normalized()*max_distance
		
		# Check upper and lower height
		if ( delta.y > max_height):
			delta.y = max_height
		if ( delta.y < min_height):
			delta.y = min_height
		
		pos = target + delta
		
		look_at_from_position(pos, target, up)
		
		# Turn a little up or down
		var t = get_transform()
		t.basis = Basis(t.basis[0], deg2rad(angle_v_adjust))*t.basis
		set_transform(t)
	
	#debug mode
	else:
		#follow the player
		var target = get_parent().get_global_transform().origin
		var delta = target - target_orig
		
		#move up and rotate to look down
		set_translation(origin+Vector3(0, 50, -origin.z)+delta)
		set_rotation_degrees(Vector3(-90, 0, 180))

func set_debug(val):
	debug = val

func _ready():
	#Set origin
	origin = get_global_transform().origin
	target_orig = get_parent().get_global_transform().origin
	
	# Find collision exceptions for ray
	var node = self
	while(node):
		if (node is RigidBody):
			collision_exception.append(node.get_rid())
			break
		else:
			node = node.get_parent()
	set_physics_process(true)
	# This detaches the camera transform from the parent spatial node
	set_as_toplevel(true)

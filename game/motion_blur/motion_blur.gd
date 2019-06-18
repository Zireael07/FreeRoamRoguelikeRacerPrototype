tool
extends MeshInstance

var cam_pos_prev = Vector3()
var cam_rot_prev = Quat()

var cam = null
var mat = null

export var motion_blur = false

func _ready():
	mat = get_surface_material(0)
	cam = get_parent()
	#assert cam is Camera
	
	#set_process(motion_blur)
	set_visible(motion_blur)

func switch_motion_blur(boo):
	motion_blur = boo
	set_visible(boo)

func _process(delta):
	# don't waste time if not on
	if not motion_blur:
		return
	
	# paranoia
	if not cam:
		return
	if not cam is Camera:
		return
		
	# Linear velocity is just difference in positions between two frames.
	var velocity = cam.global_transform.origin - cam_pos_prev
	
	# Angular velocity is a little more complicated, as you can see.
	# See https://math.stackexchange.com/questions/160908/how-to-get-angular-velocity-from-difference-orientation-quaternion-and-time
	var cam_rot = Quat(cam.global_transform.basis)
	var cam_rot_diff = cam_rot - cam_rot_prev
	var cam_rot_conj = conjugate(cam_rot)
	var ang_vel = (cam_rot_diff * 2.0) * cam_rot_conj; 
	ang_vel = Vector3(ang_vel.x, ang_vel.y, ang_vel.z) # Convert Quat to Vector3
	
	mat.set_shader_param("linear_velocity", velocity)
	mat.set_shader_param("angular_velocity", ang_vel)
		
	cam_pos_prev = cam.global_transform.origin
	cam_rot_prev = Quat(cam.global_transform.basis)
	
# Calculate the conjugate of a quaternion.
func conjugate(quat):
	return Quat(-quat.x, -quat.y, -quat.z, quat.w)

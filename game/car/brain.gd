# makes the actual decisions
extends "boid.gd"

# Declare member variables here. Examples:

# FSM
onready var state = DrivingState.new(self)
var prev_state

#const STATE_PATHING = 0
const STATE_DRIVING  = 1

signal state_changed

signal lane_change_done

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# fsm
func set_state(new_state):
	# if we need to clean up
	#state.exit()
	prev_state = get_state()
	
#	if new_state == STATE_PATHING:
#		state = PathingState.new(self)
#	el
	if new_state == STATE_DRIVING:
		state = DrivingState.new(self)
	
	emit_signal("state_changed", self)

func get_state():
	if state is DrivingState:
		return STATE_DRIVING

# just call the state
func _physics_process(delta):
	state.update(delta)
	
# states ----------------------------------------------------
class DrivingState:
	var car
	
	func _init(car):
		self.car = car

	func update(delta):
		# behavior
		# steering behaviors operate in local space
		# the target passed is already local unless something went very wrong
		#steer = seek(to_local(target))
		# keeps enough speed to move while staying on track
		var spd_steer = car.match_velocity_length(50)
		#print("Spd steer" + str(spd_steer))
		# the value here (how many car lengths) should probably be speed dependent (15 works fine for speeds < 50)
		
		# we're a 3D node, so unfortunately we can only convert Vec3
		var to_loc = car.get_global_transform().xform_inv(car.target)
		var arr = car.arrive(Vector2(to_loc.x, to_loc.z), 3)
		#var arr = car.arrive(car.to_local(car.target), 10)
		#print("Arr" + str(arr))
		#car.steer = arr;
		car.steer = spd_steer + arr;
		#car.steer = Vector2(0, car.steer.y);
		#car.steer = Vector2(arr.x, spd_steer.y);
		#print("Post: " + str(car.steer))
		# arrives exactly
	#	steer = arrive(to_local(target), 30*30)
	
		# our actual velocity
		#car.velocity = Vector2(car.get_parent().get_linear_velocity().x, car.get_parent().get_linear_velocity().z)
		# forward vector scaled by our speed
		
		var gl_tg = car.get_parent().get_global_transform().xform(Vector3(0, 0, 4))
		var rel = car.get_parent().get_global_transform().xform_inv(gl_tg)
		var vel = rel * car.get_parent().get_linear_velocity().length()
		
		#var vel = car.get_parent().forward_vec * car.get_parent().get_linear_velocity().length()
		car.velocity = Vector2(vel.x, vel.z)
		print("Vel: " + str(car.velocity))

	
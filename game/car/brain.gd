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
		# keeps enough speed to move while staying on track
		var spd_steer = car.match_velocity_length(car.max_speed) #10
		#print("Spd steer" + str(spd_steer))
		
		# we're a 3D node, so unfortunately we can only convert Vec3
		var to_loc = car.get_global_transform().xform_inv(car.target)
		
		var arr = null
		# special case for target behind us
		if car.get_parent().dot < 0:
			spd_steer = car.match_velocity_length(2) # keep going forward but very slowly...
			# hack
			car.get_parent().STEER_LIMIT = 0.5
			arr = car.align(Vector2(to_loc.x, to_loc.z))
			
			car.steer = Vector2(arr.x, spd_steer.y)
		else:
			car.get_parent().STEER_LIMIT = 0.4
			# align if angle is big and speed is slow
			if abs(car.get_parent().angle) > 1.1 and car.get_parent().speed < 10:
				arr = car.align(Vector2(to_loc.x, to_loc.z))
				# hack
				arr.y = car.match_velocity_length(2).y
			else:
				# the value here should probably be speed dependent
				arr = car.arrive(Vector2(to_loc.x, to_loc.z), 10)
				#var seek = car.seek(Vector2(to_loc.x, to_loc.z))
	
			car.get_parent().debug = false
	
			#print("Arr" + str(arr))
			#car.steer = arr;
			#car.steer = spd_steer + arr;
			#car.steer = Vector2(0, car.steer.y);
			if 'race' in car.get_parent().get_parent():
				car.steer = Vector2(arr.x, spd_steer.y);
			else:
				car.steer = Vector2(arr.x, min(arr.y, spd_steer.y));
		#print("Post: " + str(car.steer))
		# arrives exactly
	#	steer = arrive(to_local(target), 30*30)
	
		# our actual velocity
		# The x parameter doesn't seem to reflect wheel angle?
		# -z means we're moving forward
		# doesn't work if the AI is going the other way
		#car.velocity = Vector2(car.get_parent().get_angular_velocity().y, -car.get_parent().get_linear_velocity().z)
		
		
		# forward vector scaled by our speed
		var gl_tg = car.get_parent().get_global_transform().xform(Vector3(0, 0, 4))
		var rel = car.get_parent().get_global_transform().xform_inv(gl_tg)
		var vel = rel * car.get_parent().get_linear_velocity().length()
		
		#var vel = car.get_parent().forward_vec * car.get_parent().get_linear_velocity().length()
		#car.velocity = Vector2(vel.x, vel.z)
		car.velocity = Vector2(car.get_parent().get_angular_velocity().y, vel.z)
		
		# debug speed difference between old & new approach
		#var old = -car.get_parent().get_linear_velocity().z
		#if old != 0:
		#	print("old: " + str(old) + " new: " + str(vel.z) + " factor: " + str(vel.z/old))
		
		#if 'race' in car.get_parent().get_parent():
		#	print(str(car.velocity.y))
		#print("Vel: " + str(car.velocity))

	

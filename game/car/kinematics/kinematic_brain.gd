extends "kinematic_boid.gd"

# Declare member variables here. Examples:
# FSM
onready var state = DrivingState.new(self)
var prev_state

#const STATE_PATHING = 0
const STATE_DRIVING  = 1
const STATE_CHASE = 2
const STATE_BUILDING = 3
const STATE_OBSTACLE = 4
const STATE_CAR_AHEAD = 5


signal state_changed


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# fsm
func set_state(new_state, param=null):
	# if we need to clean up
	#state.exit()
	prev_state = get_state()
	
#	if new_state == STATE_PATHING:
#		state = PathingState.new(self)
#	el
	if new_state == STATE_DRIVING:
		state = DrivingState.new(self)
	if new_state == STATE_CHASE:
		state = ChaseState.new(self)
	if new_state == STATE_BUILDING:
		state = BuildingAvoidState.new(self, param)
	if new_state == STATE_OBSTACLE:
		state = ObstacleState.new(self, param)
	if new_state == STATE_CAR_AHEAD:
		state = CarAheadState.new(self, param)
	
	emit_signal("state_changed", self)

func get_state():
	if state is DrivingState:
		return STATE_DRIVING
	if state is ChaseState:
		return STATE_CHASE
	if state is BuildingAvoidState:
		return STATE_BUILDING
	if state is ObstacleState:
		return STATE_OBSTACLE
	if state is CarAheadState:
		return STATE_CAR_AHEAD

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
		# keeps enough speed to move while staying on track
		var spd_steer = car.match_velocity_length(10)
		
		var arr = null
		# special case for target behind us
		# NOTE: if don't exclude reverse, AI is able to slowly drive in reverse to assigned point... something to consider in the future?
#		if car.get_parent().dot > 0 and not car.get_parent().reverse:
#			spd_steer = car.match_velocity_length(3) # keep going forward but very slowly...
#			# hack
#			car.get_parent().STEER_LIMIT = 0.5
#			#arr = car.align(Vector2(to_loc.x, to_loc.z))
#			#car.steer = Vector2(arr.x, spd_steer.y)
#			car.steer = spd_steer
#		else:
#			car.get_parent().STEER_LIMIT = 0.4
#			# align if angle is big and speed is slow
#			if abs(car.get_parent().angle) > 1.1 and car.get_parent().speed < 10:
#				arr = car.arrive(car.target, 10)
#				#var seek = car.seek(Vector2(to_loc.x, to_loc.z))
#
#				car.steer = arr
#				pass
#				#arr = car.align(Vector2(to_loc.x, to_loc.z))
#				# hack
#				#arr.y = car.match_velocity_length(3).y
#			else:
			
		# TODO: the value here should probably be speed dependent
		arr = car.arrive(car.target, 10)
		#var seek = car.seek(Vector2(to_loc.x, to_loc.z))
				
		car.steer = arr
				
				# avoid getting too far off lane
#				if car.get_parent().cte > 1 and car.get_parent().cte < 20:
#					# steer > 0 is left, < 0 is right
#					var sig = sign(arr.x)
#					arr.x = arr.x + sig*car.get_parent().cte
	
			#car.get_parent().debug = false
	
			#print("Arr" + str(arr))
			#car.steer = arr;
			#car.steer = spd_steer + arr;
			#car.steer = Vector2(0, car.steer.y);
#			if 'race' in car.get_parent().get_parent():
#				car.steer = Vector2(arr.x, spd_steer.y)
#			else:
#				car.steer = Vector2(arr.x, min(arr.y, spd_steer.y))
				
		car.velocity = car.get_parent().velocity
				
class ChaseState:
	var car
	
	func _init(car):
		self.car = car

	func update(delta):
		print("Chase state on!")
		
		var seek = car.seek(car.target)
		car.steer = seek
		car.velocity = car.get_parent().velocity

class BuildingAvoidState:
	var car
	var target
	
	func _init(car, tg):
		self.car = car
		self.target = tg

	func update(delta):
		print("Stub")
		
class ObstacleState:
	var car
	var obstacle
	
	func _init(car, obst):
		self.car = car
		self.obstacle = obst

	func update(delta):
		# behavior
		print("Stub")
		
class CarAheadState:
	var car
	var obstacle
	
	func _init(car, obst):
		self.car = car
		self.obstacle = obst

	func update(delta):
		# behavior
		var obst_dir = obstacle.forward_vec
		var dot = car.get_parent().forward_vec.dot(obst_dir)

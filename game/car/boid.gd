# steering behaviors implementation
extends Spatial

# class member variables go here, for example:
var velocity = Vector2(0,0)
var steer = Vector2(0,0)
var desired = Vector2(0,0)

var dist = 0.0


var max_speed = 50
var max_force = 15 #9
export(Vector2) var target = Vector2(800,700) # dummy

var lane_change_deg = 20
var lane_change_dist_factor = 1
var loc_tg


func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	max_speed = 50 # speed limit   #get_parent().top_speed
	#marker = get_parent().get_node("target_marker")
	
	# test changing lanes
	
	#loc_tg = (get_parent().forward_vec*lane_change_dist_factor).rotated(deg2rad(lane_change_deg))
	#target = to_global(loc_tg)
	#marker.set_position(loc_tg)
	
	#var loc_tg2 = (get_parent().forward_vec*2).rotated(deg2rad(-30))
	#ult_tg = loc_tg+loc_tg2
	
	# test normal driving
	#marker.set_position(to_local(target))
	
#	pass

func _physics_process(delta):
	# test
#	steer = match_velocity_length(10)
#	# combine two behaviors
#	# this is global 45 degrees, not local
#	steer += align(deg2rad(45))
#
#	# use real velocity to decide
#	# _velocity is rotated by parent's rotation, so we use the one that's rotated to fitt
#	velocity = get_parent().motion

	
	# normal stuff
#	velocity += steer
	# don't exceed max speed
	#velocity = velocity.normalized() * max_speed
#	velocity = velocity.clamped(max_speed)
	pass

# ------------------------------------------
# steering behaviors
func seek(target):
	# make the code universal
	# can be passed both a vector2 or a node
	if not typeof(target) == TYPE_VECTOR2:
		if "position" in target:
			# steering behaviors operate in local space
			target = to_local(target.get_global_position())
	
#	print("tg: " + str(target))
#	print("position: " + str(get_global_position()))
	
	var steering = Vector2(0,0)
	#print("Tg: " + str(target_obj.get_position()) + " " + str(get_position()))
	
	desired = target - Vector2(get_translation().x, get_translation().z)
	dist = desired.length()
#	print("des: " + str(desired))
	desired = desired.normalized() * max_speed
	#print("max speed des: " + str(desired))
	#print("vel " + str(velocity))
	# desired minus current vel
	steering = (desired - velocity).clamped(max_force)
	#print(str(steering))
	#steering = steering.clamped(max_force)
	#print(str(steering))
	
	return(steering)

func arrive(target, slowing_radius):
	var steering = Vector2(0,0)
	#print("Arrive @: " + str(target) + " " + str(get_translation()))

	desired = target - Vector2(get_translation().x, get_translation().z)
	#print("Desired " + str(desired))
	dist = desired.length()
	#print("Dist: " + str(dist))
	
	if dist < slowing_radius:
#		print("Slowing... " + str(dist/slowing_radius))
		# inside slowing area
		desired = desired.normalized() * max_speed * (dist / slowing_radius)
		
	else:
		#print("Not slowing")
		# outside
		desired = desired.normalized() * max_speed

	# desired minus current vel
	steering = (desired - velocity).clamped(max_force)

	return (steering)


# helper to map orientation to range
# works on radians
func mapToRange(orientation):
	while ((orientation > PI) || (orientation < -PI)):
		if (orientation > PI):
			orientation -= 2 * PI
		elif (orientation < -PI):
			orientation += 2 * PI;

	return orientation;
	
# target is a vector2
func align(target):
	var steering = Vector2(0,0)
	
	#2D angle to target (local coords)
	var angle = atan2(target.x, target.y)

	var change = angle
	change = mapToRange(change)
	
	#our priority is to angle up asap
	var max_force = 25 # assume this behavior is always used at low speed 
	
	# match sign
	if sign(change) == -1:
		max_force = max_force * -1
	
	#print("Orientation change is " + str(change))
	
	if abs(change) < 0.1: # tolerance
		#print("Orientation hit tolerance")
		steering = Vector2(0,0)
		#get_parent().stop = true
		# early return
		#return (steering)
	else:
		if abs(change) < deg2rad(35): # slow radius
			# pretty much the same as arrive but for floats not vectors
			steering = Vector2(clamp(max_force, -1, 1) * (abs(change) /deg2rad(15)), 0)
			#print("steer: " + str(steering))
		else:
			steering = Vector2(max_force, 0)
			#print("Steer: " + str(steering))
	
	#print("Align steer: " + str(steering))
	return (steering)

# for holding speed
func match_velocity_length(target, reverse=false):
	var steering = Vector2(0,0)

	var change = target - velocity.length()
	#print("Change: " + str(change) + " speed " + str(velocity.length()))
	
	# get it moving if velocity is 0
	var vel_for_des
	if target > 0 and velocity.length() == 0: #< 0.01:
		#print("Pretend")
		# pretend it's bigger
		vel_for_des = Vector2(0,1)
	else:
		# ignore reverse
		if not reverse and velocity.y < 0:
			vel_for_des = Vector2(velocity.x, -velocity.y)
		# force reverse
		elif reverse and velocity.y > 0:
			vel_for_des = Vector2(velocity.x, -velocity.y)
		else:
			vel_for_des = velocity
		
	#print("Vel: " + str(vel_for_des) + " normalized " + str(vel_for_des.normalized()))
	
	desired = vel_for_des.normalized() * target
	#print("Des: " + str(desired))
	
	
	steering = (desired - velocity).clamped(max_force)
	# prevent slight listing
	steering = Vector2(0, steering.y)
	#print("Steer" + str(steering))
	
	

	return (steering)

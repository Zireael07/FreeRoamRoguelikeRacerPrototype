extends Node3D

var memory = []
var cull_poly = []

# testing
@export var num_rays = 16
@export var look_side = 3.0
var look_ahead = 15.0
var brake_distance = 5.0

var interest = []
var danger = []
var chosen_dir = null

# visualize rays/directions
var rays = [] 
var forward_ray = null
# Called when the node enters the scene tree for the first time.
func _ready():
	rays.resize(num_rays)
	add_rays(get_parent())
	cull_poly = create_cull_poly()
	
	interest.resize(num_rays)
	#4.x function
	interest.fill(0.0)
	danger.resize(num_rays)
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

func create_cull_poly():
	var poly = []
	poly.append(Vector2(rays[0].x, rays[0].z))
	poly.append(Vector2(rays[1].x, rays[1].z))
	# see above
	poly.append(Vector2(rays[num_rays/4].x, rays[num_rays/4].y))
	poly.append(Vector2(rays[num_rays-(num_rays/4)].x, rays[num_rays-(num_rays/4)].y))
	poly.append(Vector2(rays[(num_rays/2)-1].x, rays[(num_rays/2)-1].y))
	poly.append(Vector2(rays[num_rays/2].x, rays[num_rays/2].y))
	poly.append(Vector2(rays[(num_rays/2)+1].x, rays[(num_rays/2)+1].y))
	poly.append(Vector2(rays[num_rays-1].x, rays[num_rays-1].y))
	print("cull poly: ", poly)
	return poly

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
	for p in memory:
		# cull distant stuff
#		var d = get_parent().global_transform.origin.distance_to(p[0])
#		if d > look_ahead:
#			to_rem.append(i)
		#print("Pos: ", pos3d_to_2d(p[0]), " in poly: ", Geometry2D.is_point_in_polygon(pos3d_to_2d(p[0]), cull_poly))
		# cull stuff by poly
		if !Geometry2D.is_point_in_polygon(pos3d_to_2d(p[0]), cull_poly):
			to_rem.append(p)
		# memory sticks around for 5s
		if cur > p[1]+5000000.0:
			to_rem.append(p)

	for p in to_rem:
		var r = memory.find(p)
		if r != -1:
			memory.remove_at(r)

func _on_timer_timeout():
	update_memory()
# -------------------------
func pos3d_to_2d(pos):
	var loc = get_parent().to_local(pos)
	return Vector2(loc.x, loc.z)

func pos3d_to_grid(pos):
	return Vector2(int(pos.x), int(pos.z))

func pos_to_grid(pos2d):
	# assumption: cell is 1mx1m each so no need for further calc
	return Vector2(int(pos2d.x), int(pos2d.y))

func get_raycast_id_for_pos(pos):
	var gridp = pos3d_to_grid(get_parent().to_local(pos))
	var heading = atan2(gridp.y, gridp.x) # atan2(0,-1) = 3.14
	#print("Heading: ", heading, " N 0deg: ", heading+PI/2)
	var raycast_id = posmod(int(floor(16*(heading+PI/2)/(2*PI) + 16 + 0.5)), 16)
	#print("Raycast_id for pos ", pos, ": ", raycast_id)
	return raycast_id 

func get_blocked_raycasts():
	var blocked = {}
	for p in memory:
		var b = get_raycast_id_for_pos(p[0])
		var d = get_parent().to_local(p[0]).length()
		# don't multiplicate
		if not b in blocked:
			blocked[b] = d
		else:
			blocked[b] = min(blocked[b], d)
	#print("Blocked raycasts: ", blocked)
	return blocked

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	test_AI()
	pass
	
func test_AI():
	set_danger()
	#set_interest_path_direction() # temporarily disable to better see avoid effects
	avoid_danger()
	mask_danger()
	#merge_direction()
	#choose_direction_blended_normalized()
	choose_direction_max()

# ----------------------------------
# test AI context steering
# based on Kidscancode's https://kidscancode.org/godot_recipes/ai/context_map/
func set_interest_path_direction():
	# hmm, this works for the player demo but not for AI, what gives???
	
	# Go forward unless we have somewhere to steer
	var path_direction = -transform.basis.z
	# this means number of decision "slots" is equal to number of rays
	# Andrew Fray's GDC talk shows this does not need to be the case	
	for i in num_rays:
		var d = -get_parent().get_node("ContextRays").get_child(i).transform.basis.z
		d = d.dot(path_direction)
		interest[i] = max(0, d)


func set_danger():
	for i in num_rays:
#		var ray = $ContextRays.get_child(i)
#		danger[i] = 1.0 if ray.is_colliding() else 0.0		
		var blocks = get_blocked_raycasts()
		danger[i] = 1.0 if i in blocks else 0.0
		
		#print("D:", danger)
		
#		if danger[i] > 0.0:
#			context_has_danger = true
		
		# increase by a factor depending on distance to obstacle
		# only for stuff in front
		if i == 0 or i == 1 or i == num_rays-1 or i == num_rays-2:
			if danger[i] == 1.0:
				var d = blocks[i]
#			#if ray.is_colliding():
#				var d = global_transform.origin.distance_to(ray.get_collider().global_transform.origin)
				danger[i] = look_ahead-d
				#if d < brake_distance*0.75:
				#	danger[i] += brake_distance-d
					
#		if ray.is_colliding():
#			# spread danger to neighboring rays
#			if i-1 > 0:
#				danger[i-1] = 1.0
#			if i+1 < num_rays:
#				danger[i+1] = 1.0

func mask_danger():
	for i in num_rays:
		if danger[i] > 0.0:
			# zero any interest in dangerous directions
			interest[i] = 0.0

# tells the AI to move to the side to avoid danger
# is symmetrical so will need a tie-breaker of some sort as the next step
func avoid_danger():
	# for tests only!
	interest.fill(0.0)
	for i in num_rays:
		if danger[i] > 0.0:
			# front rays add interest to the side
			# otherwise having all front rays blocked leads to still choosing forward direction
			
			if i in [0,1,2]:
				# x-(x/4) is to the left
				interest[i+num_rays-(num_rays/4)] = danger[i]
				# num_rays/4 is to the right
				interest[i+(num_rays/4)] = danger[i]
				
			if i in [num_rays-1, num_rays-2]:
				interest[-(num_rays-i)+num_rays-(num_rays/4)] = danger[i]
				interest[-(num_rays-i)+(num_rays/4)] = danger[i]
		
		#if i == 0 or i == 1 or i == 2:
			#if interest[num_rays-(num_rays/4)] > 0.0:
				# x-(x/4) is to the left
				# adding means we won't get stuck if all or most front rays encounter something
			#	interest[num_rays-(num_rays/4)] += 2.0*danger[i]
#			if interest[num_rays-(num_rays/4)+i] > 0.0:
#				interest[num_rays-(num_rays/4)+i] = danger[i]
#		if i == num_rays-1 or i == num_rays-2:
#			# num_rays/4 is to the right
#			# see above
#			if interest[num_rays/4] > 0.0:
#				interest[num_rays/4] += 2.0*danger[i]
#			if interest[num_rays/4+(i-num_rays)] > 0.0:
#				interest[(num_rays/4)+(i-num_rays)] = danger[i]
# only done if we have danger in the first place
func merge_direction():
	for i in num_rays:
		if danger[i] > 0.0:
			# zero any interest in dangerous directions
			interest[i] = 0.0
			
			# danger	"poisons" neighboring directions
			if i-1 > 0:
				if interest[i-1] > 0.0:
					interest[i-1] = clamp(0.5*(1-danger[i]), 0, 0.5)
			if i+1 < num_rays:
				if interest[i+1] > 0.0:
					interest[i+1] = clamp(0.5*(1-danger[i]), 0, 0.5)
			
			# TODO: add interest in opposing direction?
			# front rays add interest to the side
			# otherwise having all front rays blocked leads to still choosing forward direction
			if i == 0 or i == 1 or i == 2:
				if interest[num_rays-(num_rays/4)] > 0.0:
					# x-(x/4) is to the left
					# adding means we won't get stuck if all or most front rays encounter something
					interest[num_rays-(num_rays/4)] += 2.0*danger[i]
				if interest[num_rays-(num_rays/4)+i] > 0.0:
					interest[num_rays-(num_rays/4)+i] = danger[i]
			if i == num_rays-1 or i == num_rays-2:
				# num_rays/4 is to the right
				# see above
				if interest[num_rays/4] > 0.0:
					interest[num_rays/4] += 2.0*danger[i]
				if interest[num_rays/4+(i-num_rays)] > 0.0:
					interest[(num_rays/4)+(i-num_rays)] = danger[i]
func choose_direction_max():
	chosen_dir = Vector3.ZERO
	var i = interest.find(interest.max()) 
	#print(i)
	# local
	chosen_dir = -get_parent().get_node("ContextRays").get_child(i).transform.basis.z * interest.max()
	chosen_dir = chosen_dir.normalized()
	#print("Chosen max loc: ", chosen_dir)
# this method requires all the components to be normalized, else it returns weird stuff
# either ensure all interests are in [0,1] range or call normalize in the loop
func choose_direction_blended_normalized():
	chosen_dir = Vector3.ZERO
	for i in num_rays:
		# this is GLOBAL!!!!
		#print("Adding dir: ", -get_parent().get_node("ContextRays").get_child(i).global_transform.basis.z * interest[i])
		chosen_dir += -get_parent().get_node("ContextRays").get_child(i).global_transform.basis.z * interest[i]
	chosen_dir = chosen_dir.normalized()
	#print("chosen: ", chosen_dir)

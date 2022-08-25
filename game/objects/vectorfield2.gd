extends Area3D

var car = null
var player_script
var draw

# Called when the node enters the scene tree for the first time.
func _ready():
	#EventBus.connect("mapgen_done", setup)
	player_script = load("res://car/kinematics/kinematic_vehicle_player.gd")
	
func setup():
	var player = get_tree().get_nodes_in_group("player")[0]
	draw = player.get_node(^"BODY/root/DebugDraw3D")
	var pos = get_global_transform().origin
	draw.add_line(self, pos, pos+Vector3(5,0,0), 3, Color(1,1,0))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if car:
		var loc = to_local(car.global_transform.origin)
		if car is player_script:
			var gl_dir = global_transform * Vector3(loc.x*5, 0, 0)
			#print("Dir: ", Vector3(loc.x*5, 0, 0))
			car.map.get_node(^"nav").debug_cube(car.map.to_local(gl_dir), "flip")
			# global -> local
			car.get_node("occupancy_map").chosen_dir = gl_dir.normalized() * car.get_parent().global_transform.basis #.basis.z

			# draw
			#if get_viewport().get_camera_3d().get_name() == "CameraDebug":
			#	var local = gl_dir * global_transform
			#	#print("dir, ", local)
			#	draw.update_line(self, 0, get_global_transform().origin, get_global_transform().origin+gl_dir.normalized()*2)

#			print("Loc: ", loc, "dir ", Vector3(-loc.y+10, 0, loc.x+10))
#			#var dir = Vector3(loc).normal()
#			var dir = global_transform * Vector3(-loc.y+10, 0, loc.x+10) # should be rotational
#			#print("Dir: ", dir.normalized())
#			car.get_node("occupancy_map").chosen_dir = dir.normalized()
		#print("Test: ", loc.)
	pass


func _on_area_3d_body_entered(body):
	if body is CharacterBody3D:
		car = body
	pass # Replace with function body.


func _on_area_3d_body_exited(body):
	if car:
		car = null
	pass # Replace with function body.body
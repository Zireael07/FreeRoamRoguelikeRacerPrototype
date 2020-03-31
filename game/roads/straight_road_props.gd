tool
extends Node

# Declare member variables here. Examples:

var roadwidth = 3

#props
var building = null
#var building_test = null
var buildDistance = 10
#var numBuildings = 6
var buildingSpacing = 15
var treeSpacing = 10
# how far is the first building offset from road start (prevents overlapping with other roads/intersections)
var buildOffset = 6

# materials
var building_tex1 = null
var building_tex2 = null
var sign_tex1 = null
var sign_tex2 = null
var sign_tex3 = null
var win_mat = null
var win_mat2 = null
var cables = null
var cherry_tree = null
var bamboo_clump = null

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#props
	#building = preload("res://objects/skyscraper.tscn")
	#building = preload("res://objects/skyscraper-cube.tscn")
	building = preload("res://objects/procedural_building.tscn")
	building_tex1 = preload("res://assets/cement.tres")
	building_tex2 = preload("res://assets/brick_wall.tres")
	
	#building_test = preload("res://objects/test_shader_building.tscn")
	
	# more props
	sign_tex1 = preload("res://assets/neon_sign1.tres")
	sign_tex2 = preload("res://assets/neon_sign2.tres")
	sign_tex3 = preload("res://assets/neon_sign3.tres")
	# props
	win_mat = preload("res://assets/windows_material.tres")
	win_mat2 = preload("res://assets/windows_material2.tres")
	cables = preload("res://objects/china_cable.tscn")
	cherry_tree = preload("res://objects/cherry_tree.tscn")
	bamboo_clump = preload("res://objects/bamboo_clump.tscn")


func place_props(trees, bamboo, long):
	# buildings and lanterns
	if not trees and not bamboo:
		var numBuildings = int(long/buildingSpacing)
		for index in range(numBuildings+1):
			placeBuilding(index)
			placeCable(index)
	elif not bamboo:
		var numTrees = int(long/treeSpacing)
		for index in range(numTrees+1):
			placeTree(index)
	else:
		var numTrees = int(long/(treeSpacing/2))
		for index in range(numTrees+1):
			placeBamboo(index)

func setupBuilding(index):
	# seed the rng
	randomize()
	
	var ran = randf()
	
	var build = building.instance()
	
	if ran < 0.2:
		var mat = building_tex2
		build.material = mat
	else:
		var mat = building_tex1
		build.material = mat
	
	# storeys
	# number between 0-10
	var rani = randi() % 11
	build.storeys = 16 + rani
	
	# windows color
#	var ran_color_r = randf()
#	var ran_color_g = randf()
#	var ran_color_b = randf()
	
	if ran < 0.5:
		var win_color = win_mat
		build.windows_mat = win_color
	else:
		var win_color = win_mat2
		build.windows_mat = win_color
	
	# windows
	build.wind_width = 0.5
	build.wind_height = 0.5
	
	#build.windows_mat.set_albedo(Color(ran_color_r, ran_color_g, ran_color_b))
	
		
	# sign material
	var rand = randf()
	
	
	if rand < 0.33:
		var sign_mat = sign_tex1
		build.get_node("MeshInstance").set_surface_material(0, sign_mat)
	elif rand < 0.66:
		var sign_mat = sign_tex2
		build.get_node("MeshInstance").set_surface_material(0, sign_mat)
	else:
		var sign_mat = sign_tex3
		build.get_node("MeshInstance").set_surface_material(0, sign_mat)
	
	# vary sign placement height
	var rand_i = randi() % 5
	
	build.get_node("MeshInstance").translate(Vector3(0, rand_i, 0))
	
	
	#build.set_scale(Vector3(2, 2, 2))
	build.set_name("Skyscraper"+String(index))
	add_child(build)
	
	return build

#func setupBuildingSimple(index):
#	#var build = building.instance()
#	var build = building_test.instance()
#
#	build.set_name("Skyscraper"+String(index))
#	add_child(build)
#
#	return build

func placeBuilding(index):
	var build = setupBuilding(index)
	#var build = setupBuildingSimple(index)
	
	#left side of the road
	var loc = Vector3(roadwidth+buildDistance, 0, index+buildOffset)
	if (index > 0):
		loc = Vector3(roadwidth+buildDistance, 0, buildOffset + index*15)
	else:
		loc = Vector3(roadwidth+buildDistance, 0, index+buildOffset)
	
	build.set_translation(loc)
	build.set_rotation_degrees(Vector3(0, 180, 0))
	
	build = setupBuilding(index)
	
	#build = setupBuildingSimple(index)
	
	#right side of the road
	loc = Vector3(-(roadwidth+buildDistance), 0, index+buildOffset)
	if (index > 0):
		loc = Vector3(-(roadwidth+buildDistance), 0, buildOffset + index*15)
	else:
		loc = Vector3(-(roadwidth+buildDistance), 0, index+buildOffset)
	
	build.set_translation(loc)
	
func placeCable(index):
	if (index % 2 > 0):
		var cable = cables.instance()
		cable.set_name("Cable"+String(index))
		add_child(cable)
	
		var loc = Vector3(0,3,index*15)
		cable.set_translation(loc)

func placeTree(index):
	var tree = cherry_tree.instance()
	tree.set_name("Tree"+String(index))
	add_child(tree)

	#left side of the road
	var loc = Vector3(roadwidth+(buildDistance/2), 0, index)
	if (index > 0):
		loc = Vector3(roadwidth+(buildDistance/2), 0, index*10)
	else:
		loc = Vector3(roadwidth+(buildDistance/2), 0, index)
	
	tree.set_translation(loc)
	
	tree = cherry_tree.instance()
	tree.set_name("Tree"+String(index))
	add_child(tree)
	
	#right side of the road
	loc = Vector3(-(roadwidth+(buildDistance/2)), 0, index)
	if (index > 0):
		loc = Vector3(-(roadwidth+(buildDistance/2)), 0, index*10)
	else:
		loc = Vector3(-(roadwidth+(buildDistance/2)), 0, index)
	
	tree.set_translation(loc)

func placeBamboo(index):
	# vary position a bit
	var rand_i = randi() % 4
	var rand = randf()
	
	
	var clump = bamboo_clump.instance()
	clump.set_name("Bamboo"+String(index))
	add_child(clump)

	#left side of the road
	var loc = Vector3(roadwidth+(buildDistance/2), 0, index)
	if (index > 0):
		if rand > 0.5:
			loc = Vector3(roadwidth+(buildDistance/2)+rand_i, 0, index*5)
		else:
			loc = Vector3(roadwidth+(buildDistance/2)-rand_i, 0, index*5)
	else:
		loc = Vector3(roadwidth+(buildDistance/2), 0, index)
	
	clump.set_translation(loc)
	
	clump = bamboo_clump.instance()
	clump.set_name("Bamboo"+String(index))
	add_child(clump)
	
	# vary position a bit
	rand_i = randi() % 5
	
	#right side of the road
	loc = Vector3(-(roadwidth+(buildDistance/2)), 0, index)
	if (index > 0):
		if rand > 0.5:
			loc = Vector3(-(roadwidth+(buildDistance/2)+rand_i), 0, index*5)
		else:
			loc = Vector3(-(roadwidth+(buildDistance/2)-rand_i), 0, index*5)
	else:
		loc = Vector3(-(roadwidth+(buildDistance/2)), 0, index)
	
	clump.set_translation(loc)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

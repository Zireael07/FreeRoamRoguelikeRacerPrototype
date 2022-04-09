@tool
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
var sign_tex1_d = null
var sign_tex1_dd = null
var sign_tex2 = null
var sign_tex3 = null


var win_mat = null
var win_mat2 = null
var win_mat3 = null
var win_mat4 = null
var win_dark = null
var win_white = null

var store_tex1 = null
var store_tex2 = null
var store_tex3 = null
var store_tex4 = null
var store_tex5 = null
var store_tex5_d = null
var store_tex6 = null
var store_tex7 = null

var cables = null
var cables2 = null
var cherry_tree = null
var bamboo_clump = null
var parking_lot = null

var box = null

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#props
	#building = preload("res://objects/skyscraper.tscn")
	#building = preload("res://objects/skyscraper-cube.tscn")
	building = preload("res://objects/procedural_building.tscn")
	building_tex1 = preload("res://assets/cement.tres")
	building_tex2 = preload("res://assets/brick_wall.tres")
	# windows
	win_mat = preload("res://assets/windows_material.tres")
	win_mat2 = preload("res://assets/windows_material2.tres")
	win_mat3 = preload("res://assets/windows_material3.tres")
	win_mat4 = preload("res://assets/windows_material4.tres")
	win_dark = preload("res://assets/windows_material_dark.tres")
	win_white = preload("res://assets/windows_material_white.tres")
	# storefronts
	store_tex1 = preload("res://assets/storefront/storefront_material.tres")
	store_tex2 = preload("res://assets/storefront/storefront_material2.tres")
	store_tex3 = preload("res://assets/storefront/storefront_material3.tres")
	store_tex4 = preload("res://assets/storefront/storefront_material4.tres")
	#store_tex5 = preload("res://assets/storefront/storefront_material5.tres")
	store_tex5 = preload("res://assets/storefront/storefront_shader3.tres")
	store_tex6 = preload("res://assets/storefront/storefront_material6.tres")
	store_tex7 = preload("res://assets/storefront/storefront_material7.tres")
	
	store_tex5_d = store_tex5.duplicate() #color variants
	
	#building_test = preload("res://objects/test_shader_building.tscn")
	
	# more props
	sign_tex1 = preload("res://assets/neon_sign1.tres")
	sign_tex2 = preload("res://assets/neon_sign2.tres")
	sign_tex3 = preload("res://assets/neon_sign3.tres")
	sign_tex1_d = sign_tex1.duplicate() # color variants
	sign_tex1_dd = sign_tex1.duplicate()
	# props
	cables = preload("res://objects/china_cable.tscn")
	cables2 = preload("res://objects/lantern_cable.tscn")
	cherry_tree = preload("res://objects/cherry_tree.tscn")
	bamboo_clump = preload("res://objects/bamboo_clump.tscn")
	parking_lot = preload("res://roads/parking_lot.tscn")

	box = preload("res://objects/cardboard_box.tscn")

func place_props(trees, bamboo, long):
	var height = 0
	if get_parent().global_transform.origin.y > 1:
		height = -get_parent().global_transform.origin.y
		
	# buildings and lanterns
	if not trees and not bamboo:
		var numBuildings = int(long/buildingSpacing)
		# randomize
		randomize()
		var pk = randi_range(1, numBuildings) # new in 4.0
		
		for index in range(numBuildings+1):
			if index == pk:
				placeLot(index)
			else:
				placeBuilding(index, height)
				placeCable(index, height)
	elif not bamboo:
		var numTrees = int(long/treeSpacing)
		for index in range(numTrees+1):
			placeTree(index, height)
	else:
		var numTrees = int(long/(treeSpacing/2))
		for index in range(numTrees+1):
			placeBamboo(index, height)

func setupBuilding(index, base_height):
	# seed the rng
	randomize()
	
	var ran = randf()
	
	var build = building.instantiate()
	
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
	var win_color = win_mat
	if ran < 0.1:
		win_color = win_dark
	elif ran < 0.3:
		win_color = win_white
	elif ran < 0.4:
		win_color = win_mat2
	elif ran < 0.6:
		win_color = win_mat3
	elif ran < 0.8:
		win_color = win_mat4
	else:
		win_color = win_mat
		
	build.windows_mat = win_color
	
	# windows
	build.wind_width = 0.5
	build.wind_height = 0.5

	# storefronts
	ran = randf()
	if ran > 0.25:
		build.storefront = true
		
		# select storefront texture
		var rand = randf()
		var store_tex = store_tex1
		if rand < 0.1:
			store_tex = store_tex3 # derelict
		elif rand < 0.2:
			store_tex = store_tex4 # derelict
		elif rand < 0.3:
			store_tex = store_tex6
		elif rand < 0.5:
			store_tex = store_tex5_d
		elif rand < 0.6:
			store_tex = store_tex5
		elif rand < 0.7:
			store_tex = store_tex2
		elif rand < 0.9:
			store_tex = store_tex7
		else:
			store_tex = store_tex1
			
		build.storefront_mat = store_tex
		
		# procedural color
		if store_tex == store_tex5 or store_tex == store_tex5_d:
			var hue = randf()
			var saturation = randf()
			var lightness = randf_range(0.25, 0.75)
			
			var color = Color.from_hsv(hue, saturation, lightness)
			
			build.storefront_mat.set_shader_param("modulate", color)
	else:
		build.storefront = false
	
		
	# sign material
	var rand = randf()
	
	if rand < 0.15:
		var sign_mat = sign_tex1
		build.get_node(^"MeshInstance3D").set_surface_override_material(0, sign_mat)
	elif rand < 0.33:
		var sign_mat = sign_tex1_d
		build.get_node(^"MeshInstance3D").set_surface_override_material(0, sign_mat)
	elif rand < 0.5:
		var sign_mat = sign_tex1_dd
		build.get_node(^"MeshInstance3D").set_surface_override_material(0, sign_mat)
	elif rand < 0.66:
		var sign_mat = sign_tex2
		build.get_node(^"MeshInstance3D").set_surface_override_material(0, sign_mat)
	else:
		var sign_mat = sign_tex3
		build.get_node(^"MeshInstance3D").set_surface_override_material(0, sign_mat)
		
	# sign color
	#var rand_color_r = randf()
	#var rand_color_g = randf()
	#var rand_color_b = randf()
	
	var hue = randf()
	var saturation = randf()
	var lightness = randf_range(0.25, 0.75)
	
	var color = Color.from_hsv(hue, saturation, lightness)
	
	#print("Sign color: ", color)
	
	build.get_node(^"MeshInstance3D").get_surface_override_material(0).set_shader_param("modulate", color)
	build.get_node("MeshInstance3D/OmniLight3D").light_color = color
	
	# vary sign placement height
	var rand_i = randi() % 5
	
	# if base_height < 0, we're building for a bridge/elevated road so let's flip the sign
	build.get_node(^"MeshInstance3D").translate(Vector3(0, -base_height+rand_i, 0))
	
	
	#build.set_scale(Vector3(2, 2, 2))
	build.set_name("Skyscraper"+var2str(index))
	add_child(build)
	
	return build

func setupBuildingSimple(index):
	var build = building.instantiate()
	#var build = building_test.instantiate()

	build.set_name("Skyscraper"+var2str(index))
	add_child(build)

	return build

func placeBuilding(index, base_height):
	var build = setupBuilding(index, base_height)
	#var build = setupBuildingSimple(index)
	
	#left side of the road
	var loc = Vector3(roadwidth+buildDistance, base_height, index+buildOffset)
	if (index > 0):
		loc = Vector3(roadwidth+buildDistance, base_height, buildOffset + index*15)
	else:
		loc = Vector3(roadwidth+buildDistance, base_height, index+buildOffset)
	
	build.set_position(loc)
	build.set_rotation(Vector3(0, deg2rad(180), 0))
	
	build.get_node(^"Node3D").set_position(Vector3(-8, 0,0))
	
	# place a cardboard box in the passage
#	var c_box = box.instantiate()
#	build.add_child(c_box)
	var c_box = build.get_node("Node3D2")
	if index > 0:
		c_box.set_position(Vector3(6,2,8))
	else:
		c_box.queue_free()
#	c_box.set_position(loc+Vector3(-8, 8,-8))
	
	build = setupBuilding(index, base_height)
	
	#build = setupBuildingSimple(index)
	
	#right side of the road
	loc = Vector3(-(roadwidth+buildDistance), base_height, index+buildOffset)
	if (index > 0):
		loc = Vector3(-(roadwidth+buildDistance), base_height, buildOffset + index*15)
	else:
		loc = Vector3(-(roadwidth+buildDistance), base_height, index+buildOffset)
	
	build.set_position(loc)
	
	# move detect area
	build.get_node(^"Node3D").set_position(Vector3(-8, 0,0))
	
	# place a cardboard box in the passage
	c_box = build.get_node("Node3D2")
	if index > 0:
		c_box.set_position(Vector3(6, 2,8))
	else:
		c_box.queue_free()
#	c_box = box.instantiate()
#	build.add_child(c_box)
#	c_box.set_position(Vector3(-10, 8,-10))
	
func placeCable(index, base_height):
	if (index % 2 > 0):
		var cable = cables.instantiate()
		
		# random selection
		randomize()
		var rand = randf()
		
		if rand > 0.2:
			var red = load("res://assets/lantern_mat_red.tres")
			# make all of them red
			cable.get_child(1).set_surface_override_material(0, red)
			cable.get_child(2).set_surface_override_material(0, red)
			cable.get_child(3).set_surface_override_material(0, red)
			cable.get_child(4).set_surface_override_material(0, red)
			cable.get_child(5).set_surface_override_material(0, red)
		
		elif rand > 0.4:
			cable = cables2.instantiate()
		
		cable.set_name("Cable"+var2str(index))
		add_child(cable)
	
		# if base_height < 0, we're building for a bridge/elevated road so let's flip the sign
		var loc = Vector3(0,-base_height+3,index*15)
		cable.set_position(loc)

func placeLot(index):
	var lot = parking_lot.instantiate()
	lot.set_name("Parking"+var2str(index))
	add_child(lot)
	
	# random selection
	randomize()
	var rand = randf()
	
	var loc = Vector3(roadwidth+buildDistance, 0.05, index+buildOffset)
	if rand < 0.5:
		#left side of the road
		if (index > 0):
			loc = Vector3(roadwidth+buildDistance, 0.05, buildOffset + index*15)
		else:
			loc = Vector3(roadwidth+buildDistance, 0.05, index+buildOffset)
	else:
		#right side of the road
		loc = Vector3(-(roadwidth+buildDistance), 0.05, index+buildOffset)
		if (index > 0):
			loc = Vector3(-(roadwidth+buildDistance), 0.05, buildOffset + index*15)
		else:
			loc = Vector3(-(roadwidth+buildDistance), 0.05, index+buildOffset)
	
	lot.set_position(loc)
	
	# TODO: spawn a building on the opposite side


func placeTree(index, base_height):
	var tree = cherry_tree.instantiate()
	tree.set_name("Tree"+var2str(index))
	add_child(tree)

	#left side of the road
	var loc = Vector3(roadwidth+(buildDistance/2), base_height, index)
	if (index > 0):
		loc = Vector3(roadwidth+(buildDistance/2), base_height, index*10)
	else:
		loc = Vector3(roadwidth+(buildDistance/2), base_height, index)
	
	tree.set_position(loc)
	
	tree = cherry_tree.instantiate()
	tree.set_name("Tree"+var2str(index))
	add_child(tree)
	
	#right side of the road
	loc = Vector3(-(roadwidth+(buildDistance/2)), base_height, index)
	if (index > 0):
		loc = Vector3(-(roadwidth+(buildDistance/2)), base_height, index*10)
	else:
		loc = Vector3(-(roadwidth+(buildDistance/2)), base_height, index)
	
	tree.set_position(loc)

func placeBamboo(index, base_height):
	# vary position a bit
	var rand_i = randi() % 4
	var rand = randf()
	
	
	var clump = bamboo_clump.instantiate()
	clump.set_name("Bamboo"+var2str(index))
	add_child(clump)

	#left side of the road
	var loc = Vector3(roadwidth+(buildDistance/2), base_height, index)
	if (index > 0):
		if rand > 0.5:
			loc = Vector3(roadwidth+(buildDistance/2)+rand_i, base_height, index*5)
		else:
			loc = Vector3(roadwidth+(buildDistance/2)-rand_i, base_height, index*5)
	else:
		loc = Vector3(roadwidth+(buildDistance/2), base_height, index)
	
	clump.set_position(loc)
	
	clump = bamboo_clump.instantiate()
	clump.set_name("Bamboo"+var2str(index))
	add_child(clump)
	
	# vary position a bit
	rand_i = randi() % 5
	
	#right side of the road
	loc = Vector3(-(roadwidth+(buildDistance/2)), base_height, index)
	if (index > 0):
		if rand > 0.5:
			loc = Vector3(-(roadwidth+(buildDistance/2)+rand_i), base_height, index*5)
		else:
			loc = Vector3(-(roadwidth+(buildDistance/2)-rand_i), base_height, index*5)
	else:
		loc = Vector3(-(roadwidth+(buildDistance/2)), base_height, index)
	
	clump.set_position(loc)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

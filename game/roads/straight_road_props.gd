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
			var lightness = rand_range(0.25, 0.75)
			
			var color = Color.from_hsv(hue, saturation, lightness)
			
			build.storefront_mat.set_shader_param("modulate", color)
	else:
		build.storefront = false
	
		
	# sign material
	var rand = randf()
	
	if rand < 0.15:
		var sign_mat = sign_tex1
		build.get_node("MeshInstance").set_surface_material(0, sign_mat)
	elif rand < 0.33:
		var sign_mat = sign_tex1_d
		build.get_node("MeshInstance").set_surface_material(0, sign_mat)
	elif rand < 0.5:
		var sign_mat = sign_tex1_dd
		build.get_node("MeshInstance").set_surface_material(0, sign_mat)
	elif rand < 0.66:
		var sign_mat = sign_tex2
		build.get_node("MeshInstance").set_surface_material(0, sign_mat)
	else:
		var sign_mat = sign_tex3
		build.get_node("MeshInstance").set_surface_material(0, sign_mat)
		
	# sign color
	#var rand_color_r = randf()
	#var rand_color_g = randf()
	#var rand_color_b = randf()
	
	var hue = randf()
	var saturation = randf()
	var lightness = rand_range(0.25, 0.75)
	
	var color = Color.from_hsv(hue, saturation, lightness)
	
	#print("Sign color: ", color)
	
	build.get_node("MeshInstance").get_surface_material(0).set_shader_param("modulate", color)
	
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
		
		# random selection
		randomize()
		var rand = randf()
		
		if rand > 0.2:
			cable = cables2.instance()
		
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

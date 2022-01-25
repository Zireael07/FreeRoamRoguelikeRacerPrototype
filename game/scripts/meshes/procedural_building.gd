@tool 
extends "mesh_gen.gd"

# class member variables go here, for example:
@export var storeys: int = 18

@export var width: int = 6
var height = 4
@export var thick: int = 6

var wind_width = 1.0 #0.95
var wind_height = 0.95
var wind_thick = 0.1

@export var storefront = false

@export var material: StandardMaterial3D = StandardMaterial3D.new()
@export var windows_mat: StandardMaterial3D = StandardMaterial3D.new()
@export var storefront_mat: Material = StandardMaterial3D.new()

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var surface_wind = SurfaceTool.new()
	surface_wind.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var surface_store = null #dummy
	if storefront:
		surface_store = SurfaceTool.new()
		surface_store.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance3D.new()
	node.set_name("scraper")
	add_child(node)
	
	# bottom
	addCubeTexture(0,0,0, surface, material, width, 1, thick)
	
	#cube_building(surface, material, surface_wind, windows_mat, Vector3(0, 2, 0))
	cube_building_storeys(surface, material, surface_wind, windows_mat, surface_store, storefront_mat, Vector3(0,2,0), storeys)
	
	
	surface.generate_normals()
	surface_wind.generate_normals()
	if storefront:
		surface_store.generate_normals()
	
	# fix index
	surface.index()
	surface_wind.index()
	if storefront:
		surface_store.index()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())
	node.set_mesh(surface_wind.commit(node.get_mesh()))
	if storefront:
		node.set_mesh(surface_store.commit(node.get_mesh()))
	
	# yay GD 3
	# wtf it creates 7000+ vertices...
	#node.create_convex_collision()
	

	var shape = BoxShape3D.new()
	shape.set_extents(Vector3(thick,storeys+1,width))
	get_node(^"StaticBody3D/CollisionShape3D").set_translation(Vector3(0,storeys+1,0))
	get_node(^"StaticBody3D/CollisionShape3D").set_shape(shape)
	
	
	#Turn off shadows
	#node.set_cast_shadows_setting(0)
	
	# test
	#node.set_visible(false)

func cube_building_storeys(surface, material, surface_wind, windows_mat, surface_store, storefront_mat, pos, storeys):
	# building
	addCubeTexture(pos.x, pos.y, pos.z, surface, material, width, storeys+1, thick)
	
	for j in range(0, storeys):
		## windows
		# one axis (Z)
		# 0 is the center point of the building
		for i in range(-width+1, width+1, 3):
			# first storey
			if j == 0:
#				# storefront
#				if storefront:
#					pass
#					#addQuadFromCube(0, pos.y/2, thick, surface_store, storefront_mat, width, wind_height*2, wind_thick)
#					# other wall
#					#addQuadFromCube(0, pos.y/2, -thick, surface_store, storefront_mat, width, wind_height*2, wind_thick)
#				else:
					addQuadFromCube(i, pos.y+1, thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
					# other wall
					addQuadFromCube(i, pos.y+1, -thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
					
					#addCubeTexture(i, pos.y+1, thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
					# other wall
					#addCubeTexture(i, pos.y+1, -thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
				
			else:
				# one wall
				addQuadFromCube(i, pos.y+1+j*2, thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
				#addCubeTexture(i, pos.y+1+j*2, thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
				# other wall
				addQuadFromCube(i, pos.y+1+j*2, -thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
				#addCubeTexture(i, pos.y+1+j*2, -thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
				
		# other axis (X)
		# this axis faces the road
		for i in range(-thick+1, thick+1, 3):
			# first storey
			if j == 0:
				#storefront
				if storefront:
					# swap thick and height to rotate 90 deg
					addQuadFromCube(width, 0.5, 0, surface_store, storefront_mat, wind_thick, wind_height*3, width)
					# other wall
					addQuadFromCube(-width, 0.5, 0, surface_store, storefront_mat, wind_thick, wind_height*3, width)
				else:
					# one wall
					# swap thick and height to rotate 90 deg
					addQuadFromCube(width, pos.y+1, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)
					#addCubeTexture(width, pos.y+1, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)
					# other wall
					addQuadFromCube(-width, pos.y+1, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)
					#addCubeTexture(-width, pos.y+1, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)
			else:
				# one wall
				# swap thick and height to rotate 90 deg
				addQuadFromCube(width, pos.y+1+j*2, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)
				#addCubeTexture(width, pos.y+1+j*2, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)
				# other wall
				addQuadFromCube(-width, pos.y+1+j*2, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)
				#addCubeTexture(-width, pos.y+1+j*2, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)
		
		# increment storey count
		#j = j+1
	
	
func cube_building(surface, material, surface_wind, windows_mat, pos):
	# building
	addCubeTexture(pos.x, pos.y, pos.z, surface, material, width, height, thick)
	
	## windows
	# one axis (Z)
	# 0 is the center point of the building
	for i in range(-width+1, width+1, 3):
		# one wall
		addCubeTexture(i, pos.y+1, thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
		addCubeTexture(i, pos.y+4, thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
		# other wall
		addCubeTexture(i, pos.y+1, -thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
		addCubeTexture(i, pos.y+4, -thick, surface_wind, windows_mat, wind_width, wind_height, wind_thick)
	
	# other axis (X)
	for i in range(-thick+1, thick+1, 3):
		# one wall
		# swap thick and height to rotate 90 deg
		addCubeTexture(width, pos.y+1, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)
		addCubeTexture(width, pos.y+4, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)
		# other wall
		addCubeTexture(-width, pos.y+1, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)
		addCubeTexture(-width, pos.y+4, i, surface_wind, windows_mat, wind_thick, wind_height, wind_width)

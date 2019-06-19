tool 
extends "mesh_gen.gd"

# class member variables go here, for example:
export(int) var storeys = 18

export(int) var width = 6
var height = 4
export(int) var thick = 6

var wind_width = 1.0 #0.95
var wind_height = 0.95
var wind_thick = 0.1

export(SpatialMaterial) var material = SpatialMaterial.new()
export(SpatialMaterial) var windows_mat = SpatialMaterial.new()

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var surface_wind = SurfaceTool.new()
	surface_wind.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("scraper")
	add_child(node)
	
	# bottom
	addCubeTexture(0,0,0, surface, material, width, 1, thick)
	
	#cube_building(surface, material, surface_wind, windows_mat, Vector3(0, 2, 0))
	cube_building_storeys(surface, material, surface_wind, windows_mat, Vector3(0,2,0), storeys)
	
	
	surface.generate_normals()
	surface_wind.generate_normals()
	
	# fix index
	surface.index()
	surface_wind.index()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())
	node.set_mesh(surface_wind.commit(node.get_mesh()))
	
	# yay GD 3
	node.create_convex_collision()
	
	#Turn off shadows
	#node.set_cast_shadows_setting(0)
	
	# test
	#node.set_visible(false)

func cube_building_storeys(surface, material, surface_wind, windows_mat, pos, storeys):
	# building
	addCubeTexture(pos.x, pos.y, pos.z, surface, material, width, storeys+1, thick)
	
	
	
	for j in range(0, storeys):
		## windows
		# one axis (Z)
		# 0 is the center point of the building
		for i in range(-width+1, width+1, 3):
			# first storey
			if j == 0:
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
		for i in range(-thick+1, thick+1, 3):
			# first storey
			if j == 0:
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
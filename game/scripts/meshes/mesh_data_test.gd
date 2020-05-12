tool
extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	#modify_plane()
	deform_cube()
	#pass

func deform_cube():
	var startt = float(OS.get_ticks_msec())
	# setup
	var mdt = MeshDataTool.new()
	var st = SurfaceTool.new()
	var mesh = $"MeshInstance".get_mesh()

	# randomness!
	randomize()

	st.create_from(mesh, 0)
	var array_plane = st.commit()
	# copies the array into mesh data tool
	var error = mdt.create_from_surface(array_plane, 0)
	# For every vertex...
	#for i in range(mdt.get_vertex_count()):
	#	var vtx = mdt.get_vertex(i)
	#	# modify y
	#	vtx.y = randf() * 2
	#	mdt.set_vertex(i, vtx)
	
	var vtx = mdt.get_vertex(7)
	# Find all vertices that share the position
	for i in range(mdt.get_vertex_count()):
		var vt = mdt.get_vertex(i)
		if vt == vtx:
			vt.x += 1
			vt.y += 0.5
			mdt.set_vertex(i, vt)
			
	#vtx.x -= 1
	#mdt.set_vertex(7, vtx)
	
	# Remove any existing surfaces
	for s in range(array_plane.get_surface_count()):
		array_plane.surface_remove(s)
	
	mdt.commit_to_surface(array_plane)
	st.create_from(array_plane, 0)
	st.generate_normals()
	$MeshInstance.mesh = st.commit()
	# time it
	var endtt = float(OS.get_ticks_msec())
	print("Execution time: %.2f" % ((endtt - startt)/1000))

# from https://digitalki.net/2018/04/25/alter-a-plane-mesh-programmatically-with-godot-3-0-2/
func modify_plane():
	var startt = float(OS.get_ticks_msec())
	# setup
	var mdt = MeshDataTool.new()
	var st = SurfaceTool.new()
	var plane_mesh = PlaneMesh.new()
	# randomness!
	randomize()
	
	
	st.create_from(plane_mesh, 0)
	var array_plane = st.commit()
	# copies the array into mesh data tool
	var error = mdt.create_from_surface(array_plane, 0)
	# For every vertex...
	for i in range(mdt.get_vertex_count()):
		var vtx = mdt.get_vertex(i)
		# modify y
		vtx.y = randf() * 2
		mdt.set_vertex(i, vtx)
	
	# Remove any existing surfaces
	for s in range(array_plane.get_surface_count()):
		array_plane.surface_remove(s)
	
	mdt.commit_to_surface(array_plane)
	st.create_from(array_plane, 0)
	st.generate_normals()
	$MeshInstance.mesh = st.commit()
	# time it
	var endtt = float(OS.get_ticks_msec())
	print("Execution time: %.2f" % ((endtt - startt)/1000))

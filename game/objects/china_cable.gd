tool
extends Spatial

# Declare member variables here. Examples:
var list = []

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# prepare list
	list.append($lantern) #.get_mesh())
	list.append($lantern1) #.get_mesh())
	list.append($lantern2) #.get_mesh())
	list.append($lantern3) #get_mesh())
	list.append($lantern4) #.get_mesh())
	
	#$"merged".queue_free()
	
	if not has_node("merged"):
		combine(list)
	
	#pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func combine(list):
	# setup
	var mdt = MeshDataTool.new()
	var st = SurfaceTool.new()
	
	var tg = MeshInstance.new()
	var base = PlaneMesh.new()
	
	# convert to arraymesh
	st.create_from(base, 0)
	var array_msh = st.commit()
	
	# Remove existing surface
	array_msh.surface_remove(0)
	
	
	for i in range(0, list.size()):
		#print("position" +  str(list[i].get_global_transform()))
		
		var mesh = list[i].get_mesh()
		st.create_from(mesh, 0)
		var array_plane = st.commit()
		# copies the array into mesh data tool
		var error = mdt.create_from_surface(array_plane, 0)
		#print(str(error))
		
		# For every vertex...
		for j in range(mdt.get_vertex_count()):
			var vtx = mdt.get_vertex(j)
			#print(str(vtx))
			# convert
			var vtx_g = vtx*list[i].get_scale()
			vtx_g = vtx_g+list[i].get_translation()
			#var vtx_g = list[i].get_global_transform().xform(vtx)
			#print("l" + str(vtx) + ": g: " + str(vtx_g))
			mdt.set_vertex(j, vtx_g)
		
		array_plane.surface_remove(0)
		
		# this always adds at the end
		mdt.commit_to_surface(array_plane)
		#print("Surface number: " + str(i))
		st.create_from(array_plane, 0)
		#st.append_from(array_plane, 0, list[i].get_global_transform())
		st.generate_normals()
	
		tg.mesh = st.commit(array_msh)
	
	# add new node
	tg.set_name("merged")	
	add_child(tg)
	# test
	#tg.set_owner(get_tree().get_edited_scene_root())
		
	
extends Reference

class_name Splerger

# Funcs:
# merge_meshinstances
# split_branch
# split
# split_by_surface

class _SplitInfo:
	var grid_size : float = 0
	var grid_size_y : float = 0
	var aabb : AABB
	var x_splits : int = 0
	var y_splits : int = 1
	var z_splits : int = 0
	var use_local_space : bool = false

# debug
var m_bDebug_Split = false


func split_branch(node : Node, attachment_node : Node, grid_size : float, grid_size_y : float = 0.0, use_local_space : bool = false):
	var si : _SplitInfo = _SplitInfo.new()
	si.grid_size = grid_size
	si.grid_size_y = grid_size_y
	si.use_local_space = use_local_space
	
	var meshlist = []
	var splitlist = []
	
	_find_meshes_recursive(node, meshlist, si)

	# record which meshes have been successfully split .. for these we will
	# remove the original mesh
	splitlist.resize(meshlist.size())

	for m in range (meshlist.size()):
		print("mesh " + meshlist[m].get_name())
		
		if split(meshlist[m], attachment_node, grid_size, grid_size_y, use_local_space) == true:
			splitlist[m] = true
	
	for m in range (meshlist.size()):
		if splitlist[m] == true:
			var mi = meshlist[m]
			mi.get_parent().remove_child(mi)
			#mi.queue_delete()
	
	print("split_branch FINISHED.")
	pass

func _get_num_splits_x(si : _SplitInfo)->int:
	var splits = int (floor (si.aabb.size.x / si.grid_size))
	if splits < 1:
		splits = 1
	return splits

func _get_num_splits_y(si : _SplitInfo)->int:
	if si.grid_size_y <= 0.00001:
		return 1
	
	var splits = int (floor (si.aabb.size.y / si.grid_size_y))
	if splits < 1:
		splits = 1
	return splits

func _get_num_splits_z(si : _SplitInfo)->int:
	var splits = int (floor (si.aabb.size.z / si.grid_size))
	if splits < 1:
		splits = 1
	return splits


func _find_meshes_recursive(node : Node, meshlist, si : _SplitInfo):
	# is it a mesh?
	if node is MeshInstance:
		var mi : MeshInstance = node as MeshInstance
		si.aabb = _calc_aabb(mi)
		print ("mesh " + mi.get_name() + "\n\tAABB " + str(si.aabb))

		var splits_x = _get_num_splits_x(si)
		var splits_y = _get_num_splits_y(si)
		var splits_z = _get_num_splits_z(si)
		
		if (splits_x + splits_y + splits_z) > 3:
			meshlist.push_back(mi)
			print ("\tfound mesh to split : " + mi.get_name())
			print ("\t\tsplits_x : " + str(splits_x) + " _y " + str(splits_y) + " _z " + str(splits_z))
			#print("\tAABB is " + str(aabb))
	
	for c in range (node.get_child_count()):
		_find_meshes_recursive(node.get_child(c), meshlist, si)



# split a mesh according to the grid size
func split(mesh_instance : MeshInstance, attachment_node : Node, grid_size : float, grid_size_y : float, use_local_space : bool = false, delete_orig : bool = false):
	
	# save all the info we can into a class to avoid passing it around
	var si : _SplitInfo = _SplitInfo.new()
	si.grid_size = grid_size
	si.grid_size_y = grid_size_y
	si.use_local_space = use_local_space
	
	# calculate the AABB
	si.aabb = _calc_aabb(mesh_instance)
	si.x_splits = _get_num_splits_x(si)
	si.y_splits = _get_num_splits_y(si)
	si.z_splits = _get_num_splits_z(si)

	print (mesh_instance.get_name() + " : x_splits " + str(si.x_splits) + " y_splits " + str(si.y_splits) + " z_splits " + str(si.z_splits))

	## no need to split .. should never happen
	if ((si.x_splits + si.y_splits + si.z_splits) == 3):
		print ("WARNING - not enough splits, ignoring")
		return false
	
	var mesh = mesh_instance.mesh

	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)

	var nVerts = mdt.get_vertex_count()
	if nVerts == 0:
		return true

	# new .. create pre transformed to world space verts, no need to transform for each split
	var world_verts = PoolVector3Array([Vector3(0, 0, 0)])
	world_verts.resize(nVerts)
	var xform = mesh_instance.global_transform
	for n in range (nVerts):
		world_verts.set(n, xform.xform(mdt.get_vertex(n)))

	print ("\tnVerts " + str(nVerts))

	# only allow faces to be assigned to one of the splits
	# i.e. prevent duplicates in more than 1 split
	var nFaces = mdt.get_face_count()
	var faces_assigned = []
	faces_assigned.resize(nFaces)

	# each split
	for z in range (si.z_splits):
		for y in range (si.y_splits):
			for x in range (si.x_splits):
				_split_mesh(mdt, mesh_instance, x, y, z, si, attachment_node, faces_assigned, world_verts)
	
	return true


#class UniqueVert:
#	var m_OrigInd : int



func _split_mesh(mdt : MeshDataTool, orig_mi : MeshInstance, grid_x : float, grid_y : float, grid_z : float, si : _SplitInfo, attachment_node : Node, faces_assigned, world_verts : PoolVector3Array):

	print ("\tsplit " + str(grid_x) + ", " + str(grid_y) + ", " + str(grid_z))

	# find the subregion of the aabb
	var xgap = si.aabb.size.x / si.x_splits
	var ygap = si.aabb.size.y / si.y_splits
	var zgap = si.aabb.size.z / si.z_splits
	var pos = si.aabb.position
	pos.x += grid_x * xgap
	pos.y += grid_y * ygap
	pos.z += grid_z * zgap
	var aabb = AABB(pos, Vector3(xgap, ygap, zgap))
	
	# godot intersection doesn't work on borders ...
	aabb = aabb.grow(0.1)
	
	if m_bDebug_Split:
		print("\tAABB : " + str(aabb))

	var nVerts = mdt.get_vertex_count()
	var nFaces = mdt.get_face_count()
	
	# find all faces that overlap the new aabb and add them to a new mesh
	var faces = []

	var face_aabb : AABB

#	var bDebug = false
#	if m_bDebug_Split && (grid_x == 0) && (grid_z == 0):
#		bDebug = true
#	var sz = ""
	
	var xform = orig_mi.global_transform
	
	for f in range (nFaces):
		#if (f % 2000) == 0:
		#	print (".")
		#if bDebug:
		#	sz = "face " + str(f) + "\n"
		
		for i in range (3):
			var ind = mdt.get_face_vertex(f, i)
			#var vert = mdt.get_vertex(ind)
			#vert = xform.xform(vert)
			var vert = world_verts[ind]

			#if bDebug:
			#	sz += "v" + str(i) + " " + str(vert) + "\n"
			
			if i == 0:
				face_aabb = AABB(vert, Vector3(0, 0, 0))
			else:
				face_aabb = face_aabb.expand(vert)
				
		#if bDebug:
		#	print(sz)
			
		# does this face overlap the aabb?
		if aabb.intersects(face_aabb):
			# only allow one split to contain a face
			if faces_assigned[f] != true:
				faces.push_back(f)
				faces_assigned[f] = true


	if faces.size() == 0:
		print("\tno faces, ignoring...")
		return

	# find unique verts
	var new_inds = []
	var unique_verts = []

	#print ("mapping start")
	# use a mapping of original to unique indices to speed up finding unique verts	
	var ind_mapping = []
	ind_mapping.resize(mdt.get_vertex_count())
	for i in range (mdt.get_vertex_count()):
		ind_mapping[i] = -1
	
	for n in range (faces.size()):
		var f = faces[n]
		for i in range (3):
			var ind = mdt.get_face_vertex(f, i)
			
			var new_ind = _find_or_add_unique_vert(ind, unique_verts, ind_mapping)
			new_inds.push_back(new_ind)
		
			
	#print ("mapping end")
			
	# create the new mesh
	var tmpMesh = Mesh.new()
	
	#print(orig_mi.get_name() + " orig mat count " + str(orig_mi.mesh.get_surface_count()))
	#var mat = orig_mi.get_surface_material(0)
	var mat = orig_mi.mesh.surface_get_material(0)
		
	#var mat = SpatialMaterial.new()
	#mat = mat_orig
	#var color = Color(0.1, 0.8, 0.1)
	#mat.albedo_color = color
	
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	#var xform = orig_mi.global_transform
	
	for u in unique_verts.size():
		var n = unique_verts[u]
		
		var vert = mdt.get_vertex(n)
		var norm = mdt.get_vertex_normal(n)
		var col = mdt.get_vertex_color(n)
		var uv = mdt.get_vertex_uv(n)
		var uv2 = mdt.get_vertex_uv2(n)
		var tang = mdt.get_vertex_tangent(n)

		if si.use_local_space == false:
			vert = xform.xform(vert)
			norm = xform.basis.xform(norm)
			norm = norm.normalized()
			tang = xform.xform(tang)
		
		if norm:
			st.add_normal(norm)
		if col:
			st.add_color(col)
		if uv:
			st.add_uv(uv)
		if uv2:
			st.add_uv2(uv2)
		if tang:
			st.add_tangent(tang)
				
		st.add_vertex(vert)

	# indices
	for i in new_inds.size():
		st.add_index(new_inds[i])
		
	#print ("commit start")

	st.commit(tmpMesh)

	var new_mi = MeshInstance.new()
	new_mi.mesh = tmpMesh
	
	new_mi.set_surface_material(0, mat)
	
	new_mi.set_name(orig_mi.get_name() + "_" + str(grid_x) + str(grid_z))
	
	if si.use_local_space:
		new_mi.transform = orig_mi.transform
	
	# add the new mesh as a child
	attachment_node.add_child(new_mi)
	pass
	
	
	
func _find_or_add_unique_vert(orig_index : int, unique_verts, ind_mapping):
	# already exists in unique verts
	if ind_mapping[orig_index] != -1:
		return ind_mapping[orig_index]
			
	# else add to list of unique verts
	var new_index = unique_verts.size()
	unique_verts.push_back(orig_index)
	
	# record this for next time
	ind_mapping[orig_index] = new_index
	
	return new_index
	

func split_by_surface(orig_mi : MeshInstance, attachment_node : Node, use_local_space : bool = false):

	print ("split_by_surface " + orig_mi.get_name())

	var mesh = orig_mi.mesh
	
	var count = mesh.get_surface_count()
	if count <= 1:
		return # nothing to do
	
	for s in range (count):
		var mdt = MeshDataTool.new()
		mdt.create_from_surface(mesh, s)
		
		var nVerts = mdt.get_vertex_count()
		if nVerts == 0:
			continue
			
		_split_mesh_by_surface(mdt, orig_mi, attachment_node, s, use_local_space)

	# delete orig mesh
	orig_mi.get_parent().remove_child(orig_mi)
	#orig_mi.queue_delete()
	
	pass

func split_multi_surface_meshes_recursive(var node : Node):
	if node is MeshInstance:
		if node.get_child_count() == 0:
			split_by_surface(node, node.get_parent())
	
	# iterate through children
	for c in range (node.get_child_count()):
		split_multi_surface_meshes_recursive(node.get_child(c))

func merge_suitable_meshes_across_branches(var root : Spatial):
	var master_list = []
	_list_mesh_instances(root, master_list)
	
	var mat_list = []
	var sub_list = []
	
	# identify materials
	for n in range (master_list.size()):
		var mat
		if master_list[n].get_surface_material_count() > 0:
			mat = master_list[n].mesh.surface_get_material(0)
		
		# is the material in the mat list already?
		var mat_id = -1
		
		for m in range (mat_list.size()):
			if mat_list[m] == mat:
				mat_id = m
				break

		# first instance of material
		if mat_id == -1:
			mat_id = mat_list.size()
			mat_list.push_back(mat)
			sub_list.push_back([])

		# mat id is the sub list to add to
		var sl = sub_list[mat_id]
		sl.push_back(master_list[n])
		print("adding " + master_list[n].get_name() + " to material sublist " + str(mat_id))

	# at this point the sub lists are complete, and we can start merging them
	for n in range (sub_list.size()):
		var sl = sub_list[n]
		
		if (sl.size() > 1):
			var new_mi : MeshInstance = merge_meshinstances(sl, root)
			
			# compensate for local transform on the parent node
			# (as the new verts will be in global space)
			var tr : Transform = root.global_transform
			tr = tr.inverse()
			new_mi.transform = tr
	


func _list_mesh_instances(var node, var list):
	if node is MeshInstance:
		if node.get_child_count() == 0:
			var mi : MeshInstance = node
			if mi.get_surface_material_count() <= 1:
				list.push_back(node)
		
	for c in range (node.get_child_count()):
		_list_mesh_instances(node.get_child(c), list)
		


func merge_suitable_meshes_recursive(var node : Node):
	# try merging child mesh instances
	_merge_suitable_child_meshes(node)
	
	# iterate through children
	for c in range (node.get_child_count()):
		merge_suitable_meshes_recursive(node.get_child(c))
	

func _merge_suitable_child_meshes(var node : Node):
	if node is Spatial:
		var spat : Spatial = node
	
		var child_list = []
		for c in range (node.get_child_count()):
			_find_suitable_meshes(child_list, node.get_child(c))
			
		if (child_list.size() > 1):
			var new_mi : MeshInstance = merge_meshinstances(child_list, node)
			
			# compensate for local transform on the parent node
			# (as the new verts will be in global space)
			var tr : Transform = spat.global_transform
			tr = tr.inverse()
			new_mi.transform = tr
		
	

func _find_suitable_meshes(var child_list, var node : Node):
	# don't want to merge meshes with children
	if node.get_child_count():
		return
	
	if node is MeshInstance:
		var mi : MeshInstance = node
		# must have only one surface
		if mi.get_surface_material_count() <= 1:
			print("found mesh instance " + mi.get_name())
	
			var mat_this = mi.mesh.surface_get_material(0)
	
			if (child_list.size() == 0):
				if (mat_this):
					print("\tadding first to list")
					child_list.push_back(mi)
				return
	
			# already exists in child list
			# must be compatible meshes
			var mat_existing = child_list[0].mesh.surface_get_material(0)
	
			if (mat_this == mat_existing):
				print("\tadding to list")
				child_list.push_back(mi)
	

func merge_meshinstances(var mesh_array, var attachment_node : Node, var use_local_space : bool = false, var delete_originals : bool = true):
	if mesh_array.size() < 2:
		printerr("merge_meshinstances array must contain at least 2 meshes")
		return

	# create the new mesh
	var tmpMesh = Mesh.new()

	var first_mi = mesh_array[0]
	
	var mat
	if first_mi is MeshInstance:
		mat = first_mi.mesh.surface_get_material(0)
	else:
		printerr("merge_meshinstances array must contain mesh instances")
		return
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)

	var vertex_count : int = 0

	for n in range (mesh_array.size()):
		vertex_count = _merge_meshinstance(st, mesh_array[n], use_local_space, vertex_count)

	st.commit(tmpMesh)

	var new_mi = MeshInstance.new()
	new_mi.mesh = tmpMesh
	
	new_mi.set_surface_material(0, mat)
	
	if use_local_space:
		new_mi.transform = first_mi.transform
	
	var sz = first_mi.get_name() + "_merged"
	new_mi.set_name(sz)
	
	# add the new mesh as a child
	attachment_node.add_child(new_mi)
	
	if delete_originals:
		for n in range (mesh_array.size()):
			var mi = mesh_array[n]
			var parent = mi.get_parent()
			if parent:
				parent.remove_child(mi)
			mi.queue_free()
			
	# return the new mesh instance as it can be useful to change transform
	return new_mi
		

func _merge_meshinstance(st : SurfaceTool, mi : MeshInstance, var use_local_space : bool, var vertex_count : int):
	if mi == null:
		printerr("_merge_meshinstance - not a mesh instance, ignoring")
		return vertex_count

	print("merging meshinstance : " + mi.get_name())		
	var mesh = mi.mesh
		
	var mdt = MeshDataTool.new()
	
	# only surface 0 for now
	mdt.create_from_surface(mesh, 0)

	var nVerts = mdt.get_vertex_count()
	var nFaces = mdt.get_face_count()

	var xform = mi.global_transform
	
	for n in nVerts:
		var vert = mdt.get_vertex(n)
		var norm = mdt.get_vertex_normal(n)
		var col = mdt.get_vertex_color(n)
		var uv = mdt.get_vertex_uv(n)
		var uv2 = mdt.get_vertex_uv2(n)
		var tang = mdt.get_vertex_tangent(n)

		if use_local_space == false:
			vert = xform.xform(vert)
			norm = xform.basis.xform(norm)
			norm = norm.normalized()
			tang = xform.xform(tang)
		
		if norm:
			st.add_normal(norm)
		if col:
			st.add_color(col)
		if uv:
			st.add_uv(uv)
		if uv2:
			st.add_uv2(uv2)
		if tang:
			st.add_tangent(tang)
		st.add_vertex(vert)

	# indices
	for f in nFaces:
		for i in range (3):
			var ind = mdt.get_face_vertex(f, i)
			
			# index must take into account the vertices of previously added meshes
			st.add_index(ind + vertex_count)
			
	# new running vertex count
	return vertex_count + nVerts


func _split_mesh_by_surface(mdt : MeshDataTool, orig_mi : MeshInstance, attachment_node : Node, surf_id : int, use_local_space : bool):
	var nVerts = mdt.get_vertex_count()
	var nFaces = mdt.get_face_count()
	
	# create the new mesh
	var tmpMesh = Mesh.new()
	
	var mat = orig_mi.mesh.surface_get_material(surf_id)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	var xform = orig_mi.global_transform
	
	for n in mdt.get_vertex_count():
		var vert = mdt.get_vertex(n)
		var norm = mdt.get_vertex_normal(n)
		var col = mdt.get_vertex_color(n)
		var uv = mdt.get_vertex_uv(n)
		var uv2 = mdt.get_vertex_uv2(n)
		var tang = mdt.get_vertex_tangent(n)

		if use_local_space == false:
			vert = xform.xform(vert)
			norm = xform.basis.xform(norm)
			norm = norm.normalized()
			tang = xform.xform(tang)
		
		if norm:
			st.add_normal(norm)
		if col:
			st.add_color(col)
		if uv:
			st.add_uv(uv)
		if uv2:
			st.add_uv2(uv2)
		if tang:
			st.add_tangent(tang)
		st.add_vertex(vert)

	# indices
	for f in mdt.get_face_count():
		for i in range (3):
			var ind = mdt.get_face_vertex(f, i)
			st.add_index(ind)

	st.commit(tmpMesh)

	var new_mi = MeshInstance.new()
	new_mi.mesh = tmpMesh
	
	new_mi.set_surface_material(0, mat)
	
	if use_local_space:
		new_mi.transform = orig_mi.transform
	
	var sz = orig_mi.get_name() + "_" + str(surf_id)
	if mat:
		if mat.resource_name != "":
			sz += "_" + mat.resource_name
	new_mi.set_name(sz)
	
	# add the new mesh as a child
	attachment_node.add_child(new_mi)
	pass


func _check_aabb(aabb : AABB):
	assert (aabb.size.x >= 0)
	assert (aabb.size.y >= 0)
	assert (aabb.size.z >= 0)

func _calc_aabb(mesh_instance : MeshInstance):
	var aabb : AABB = mesh_instance.get_transformed_aabb()
	# godot intersection doesn't work on borders ...
	aabb = aabb.grow(0.1)
	return aabb
	
#	var mesh = mesh_instance.mesh
#	var mdt = MeshDataTool.new()
#	mdt.create_from_surface(mesh, 0)
#	var nVerts = mdt.get_vertex_count()
#
#	var xform = mesh_instance.global_transform
#	var aabb : AABB
#
#	for n in range (nVerts):
#		var vert = mdt.get_vertex(n)
#		vert = xform.xform(vert)
#		if n == 0:
#			aabb.position = vert
#			aabb.size = Vector3(0, 0, 0)
#		else:
#			aabb = aabb.expand(vert)
#
#	_check_aabb(aabb)

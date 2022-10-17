extends SubViewportContainer


# Declare member variables here. Examples:
var cam = null
var mouse = Vector2()
var mmap_offset 
var pan = Vector2()
var player
var map
var int_path = []
var nav_result = PackedVector3Array()

var intersections = []

# Called when the node enters the scene tree for the first time.
func _ready():
	
	cam = get_node(^"SubViewport/Camera2D")
	#the camera seems to be offset by this value from minimap center
	# experimentally determined
	mmap_offset = Vector2(74,89)

	player = get_parent()
	map = get_node(^"/root/Node3D").get_node(^"map")
	get_node(^"track").set_position(get_node(^"center").get_position() + mmap_offset)
	setup()
	
func setup():
	intersections = get_parent().get_node(^"Viewport_root/SubViewport/minimap").intersections

	for i in range(intersections.size()-1):
		var l = Label.new()
		l.set_name("Label"+str(i))
		l.set_text(str(i))
		var inter = intersections[i]
		#print("i: ", str(i), " global loc: ", inter)
		var loc = Vector2(inter.x, inter.z)
		# for some reason we need to flip
		# the offset at the end is so that the numbers are actually visible
		l.position = Vector2(-loc.x, -loc.y) + mmap_offset + Vector2(5,5)
		get_node("center").add_child(l)
		#print("Added label " + str(i) + "@" + str(l.position))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# zoom in
func _on_ButtonPlus_pressed():
	# any closer and it's too blurry
	if cam.zoom.x > 0.75:
		cam.zoom.x -= 0.25
		cam.zoom.y -= 0.25

# zoom out
func _on_ButtonMinus_pressed():
	cam.zoom.x += 0.25
	cam.zoom.y += 0.25

# panning
func _on_ButtonUp_pressed():
	pan.y -= 10 
	cam.offset = pan
	get_node(^"track").set_position(get_node(^"center").get_position() + mmap_offset - pan)
	queue_redraw()
	get_node(^"track").queue_redraw()


func _on_ButtonDown_pressed():
	pan.y += 10 
	cam.offset = pan
	get_node(^"track").set_position(get_node(^"center").get_position() + mmap_offset - pan)
	queue_redraw()
	get_node(^"track").queue_redraw()

func _on_ButtonLeft_pressed():
	pan.x -= 10 
	cam.offset = pan
	get_node(^"track").set_position(get_node(^"center").get_position() + mmap_offset - pan)
	queue_redraw()
	get_node(^"track").queue_redraw()

func _on_ButtonRight_pressed():
	pan.x += 10 
	cam.offset = pan
	get_node(^"track").set_position(get_node(^"center").get_position() + mmap_offset - pan)
	queue_redraw()
	get_node(^"track").queue_redraw()


# detect clicks
func _draw():
	if mouse != null:
		draw_rect(Rect2(mouse-pan, Vector2(8,8)), Color(1,0,0))

## inverse of pos3dtominimap from map_texture.gd
#func point2d_to3d(pos):
#	var middle = Vector2(500,500)
#	return pos+middle

# returns id of closest intersection
func find_closest_intersection(pos):
	# list of intersection global positions
	#var intersections = get_parent().get_node(^"Viewport_root/SubViewport/minimap").intersections
	
	# pos is flipped for some reason, so unflip it
	pos = -pos
	
	# sort by distance
	var dists = []
	var tmp = []
	#for inter in intersections:
	for i in range(intersections.size()-1):
		var inter = intersections[i]
		# pretend it's 2d
		var inter_pos = Vector2(inter.x, inter.z)
		var dist = inter_pos.distance_to(pos)
		tmp.append([dist, i])
		dists.append(dist)

	dists.sort()
	
	for t in tmp:
		if t[0] == dists[0]:
			#print("Target is : " + t[1].get_parent().get_name())
			
			return t[1]

func get_drawn_path(int_path):
	var nav_path = PackedVector3Array()
	var path_look = map.get_node(^"nav").path_look # shortcut
	if [int_path[0], int_path[1]] in path_look:
		#print("First pair: " + str(int_path[0]) + "," + str(int_path[1]))			
		var lookup_path = path_look[[int_path[0], int_path[1]]]
		#print("Lookup path pt1: " + str(lookup_path))
		nav_path = map.get_node(^"nav").nav.get_point_path(lookup_path[0], lookup_path[1])
		#print("Nav path: " + str(nav_path))

	var nav_path2 = PackedVector3Array()
	var nav_path3 = PackedVector3Array()
	if int_path.size() > 2 and [int_path[1], int_path[2]] in path_look:
		#print("Second pair: " + str(int_path[1]) + "," + str(int_path[2]))
		var lookup_path = path_look[[int_path[1], int_path[2]]]
		#print("Lookup path pt2: " + str(lookup_path))
		nav_path2 = map.get_node(^"nav").nav.get_point_path(lookup_path[0], lookup_path[1])
		#print("Nav path pt2 : " + str(nav_path2))

	nav_result = nav_path + nav_path2
	
	if nav_result.size() > 0:
		# show line on map
		var track_map = get_node(^"track")
		track_map.points = track_map.vec3s_convert(nav_result)
		# force redraw
		track_map.queue_redraw()
		# show on minimap, too
		var minimap_track_map = player.get_node(^"Viewport_root/SubViewport/minimap/Container/Node2D2/Control_pos/track")
		minimap_track_map.points = minimap_track_map.vec3s_convert(nav_result)
		# force redraw
		minimap_track_map.queue_redraw()

func player_nav(target):
	# look up the closest intersection
	var map_loc = map.to_local(player.get_global_transform().origin)
	#print("global: " + str(get_global_transform().origin) + ", map_loc: " + str(map_loc))
		
	# this operates on child ids
	var sorted = map.sort_intersections_distance(map_loc, true)
	var closest_ind = sorted[0][1]
	var closest = map.get_child(closest_ind)
	#print("Closest: " + str(closest.get_name()))
	
	# this operates on ids, therefore we subtract 3 from child id
	int_path = map.get_node(^"nav").ast.get_id_path(closest_ind-3, target)
	print("Intersections path: " + str(int_path))
	get_drawn_path(int_path)
	# mark #0 as reached because in 99% of cases we're already past it
	player.reached_inter = [int_path[0], 0]

func _on_MapView_gui_input(event):
	if event is InputEventMouseButton:
		mouse = event.position
		print("Clicked mouse in map viewport @ ", event.position+pan)
		# camera position is half viewport width and half viewport height
		var rel_pos = event.position+pan * get_node(^"center").get_transform()
		#print("Relative to camera: ", rel_pos)
		# somehow, this fits the intersection positions sent to minimap (just flipped signs)
		# before transforming to 2d
		#TODO: take zoom into account
		var rel_mmap = rel_pos-mmap_offset
		#print("Relative to mmap centre: ", rel_mmap)
		#print("Converted to 3d", point2d_to3d(rel_pos-mmap_offset))
		var clicked_inter = find_closest_intersection(rel_mmap)
		print("Clicked inter: ", clicked_inter)
		player_nav(clicked_inter)

		
		# draw
		queue_redraw()

func redraw_nav():
	if nav_result.size() > 0:
		# show on minimap, too
		var minimap_track_map = player.get_node(^"Viewport_root/SubViewport/minimap/Container/Node2D2/Control_pos/track")
		minimap_track_map.points = minimap_track_map.vec3s_convert(nav_result)
		# force redraw
		minimap_track_map.queue_redraw()

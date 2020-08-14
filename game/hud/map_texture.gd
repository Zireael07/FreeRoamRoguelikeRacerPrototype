extends TextureRect

# class member variables go here, for example:
var textur
var uv_offset

var image

# minimap parameters
var bg = Color(0, 0.16, 0.99, 0.55) # Color(0,1,0,1) pure green
var road = Color(1,1,1, 1) # white #Color(0,0,0,1) # pure black
var linecolor = Color(1,0,0,1)
var testcolor = bg #Color(0,0,0,1)
var dot_size = 4

# positioning
var positions = [] #Vector3Array()
var positions_2d = [] #Vector2Array()
var intersections = []
var intersections_2d = []

var indices = []


func _ready():
	# connect to the load_ended signal of the player
	get_tree().get_nodes_in_group("player")[0].get_child(0).connect("load_ended", self, "make_map")
	# TODO: clear up!
	#get_parent().get_parent().get_parent().get_parent().get_parent().connect("load_ended", self, "make_map")
	
	if not Engine.is_editor_hint():
		textur = get_texture()
		uv_offset = 1/get_size().x #assume the node's scale is 1,1
		#print("UV offset is " + String(uv_offset))		
		
	#register ourselves with the minimap root
	var player = get_tree().get_nodes_in_group("player")[0].get_child(0)
	
	player.get_node("Viewport_root/Viewport/minimap").minimap_bg = self
		
	pass

func make_map():
	var start_time = OS.get_ticks_msec()
	#print("Started at " + String(start_time))
	image = Image.new()
	image.create(1000, 1000, false, Image.FORMAT_RGBA8)
	
	#positions = get_parent().get_parent().get_parent().positions
	var player = get_tree().get_nodes_in_group("player")[0].get_child(0)
	positions = player.get_node("Viewport_root/Viewport/minimap").positions
	
	#draw background
	# massive speed up
	image.fill(bg)
	
	# necessary in 3.0
	image.lock()
	
	#draw center point (=0,0)
	var pos_c = Vector2(image.get_width()/2, image.get_height()/2)
	for i in range (pos_c.x-(dot_size+1), pos_c.x+(dot_size+1)):
		for j in range (pos_c.y-(dot_size+1), pos_c.y+(dot_size+1)):
			image.set_pixel(i,j, testcolor)
	
	intersections = player.get_node("Viewport_root/Viewport/minimap").intersections
	
	if intersections.size() == 0:
		print("No intersections detected")
	else:
		for ind in range (intersections.size()):
			var pos = intersections[ind]
			var temp = []
			var calc_point = pos3d_to_minimap_point(pos)
			temp.push_back(calc_point)
			#positions_2d.push_back(calc_point)
			intersections_2d.append(temp)
			
		# draw them as real big dots
		for ind in range (intersections_2d.size()):
			var pos = intersections_2d[ind][0]
			#print("Pos: " + str(pos))
			if pos.x > 1000-dot_size+1 or pos.y > 1000-dot_size+1 or pos.x-dot_size+1 < 0 or pos.y-dot_size+1 < 0:
				print("Out of borders")
			else:
				#center the point
				for i in range (pos.x-(dot_size+1), pos.x+(dot_size+1)):
					for j in range (pos.y-(dot_size+1), pos.y+(dot_size+1)):
						# paranoia
						if i > 0 and i < 1000 and j > 0 and j < 1000:
							# necessary in 3.0
							image.lock()
							image.set_pixel(i,j, road)
							
	if positions.size() == 0:
		print("No positions detected")
	else:
		for index in range (positions.size()):
			var temp = []
			
			for pos in positions[index]:
				var calc_point = pos3d_to_minimap_point(pos)
				temp.push_back(calc_point)
				#positions_2d.push_back(calc_point)
				positions_2d.append(temp)
		
		# put dots on positions
		for index in range (positions_2d.size()):
			for ind in range(positions_2d[index].size()):
				var vec = positions_2d[index][ind]
				#print("Vec: " + str(vec))
				# abort early if we're out of borders
				if vec.x > 1000-dot_size or vec.y > 1000-dot_size or vec.x <0 or vec.y < 0: 
					print("Out of borders")
					#return
				else:
					for i in range (vec.x, vec.x+dot_size):
						for j in range (vec.y, vec.y+dot_size):
							# paranoia
							if i > 0 and i < 1000 and j > 0 and j < 1000:
								# necessary in 3.0
								image.lock()
								image.set_pixel(i,j, road)

					draw_lines(ind, index)
			
			# debugging purposes
			#draw_lines_differently(index)

	
	var exec_time = OS.get_ticks_msec() - start_time
	print("Minimap generation execution time: " + String(exec_time))
	
	##textur = load("res://map_edited.png") #set_data(image)
	
	textur = ImageTexture.new()
	print("Creating image tex from data")
	textur.create_from_image(image)
	
	set_texture(textur)
	
	# save for later
	image.save_png("res://map_edited.png")

	#register ourselves with the parent
	#get_parent().get_parent().get_parent().minimap_bg = self
	#player = get_tree().get_nodes_in_group("player")[0].get_child(0)
	
	player.get_node("Viewport_root/Viewport/minimap").minimap_bg = self
	
# drawing
func pos3d_to_minimap_point(pos):
	#the midpoint of map is equal to 0,0 in 3d
	#var middle = Vector2(image.get_width()/2, image.get_height()/2)
	var middle = Vector2(500, 500)
	
	#print("Midpoint of map is " + String(middle))
	
	var x = round(middle.x - pos.x)
	var y = round(middle.y - pos.z)
	#print("Calculated position for pos " + String(pos) + "is x " + String(x) + " y " + String(y))
	
	#3d x is left/right (inc left) and z is forward/back (up/down)
	#2d x is left/right (increases right) and y is top/down (from top)
	return Vector2(x, y)

func draw_lines(ind, index):
	if ind < positions_2d[index].size()-1:
		var vec = positions_2d[index][ind]
		# automatically draw lines
		var start = vec
		var end = positions_2d[index][ind+1]
#						
		var line = bresenham_complex(start, end)
		for index in range (line.size()):
			for i in range(line[index].x, line[index].x+dot_size):
				for j in range(line[index].y, line[index].y+dot_size):
					# paranoia
					if i > 0 and i < 1000 and j > 0 and j < 1000:
						# necessary in 3.0
						image.lock()
						image.set_pixel(i,j, road)

#for debugging purposes, different colors for straight vs. curves
func draw_lines_differently(index):
	# if we're a straight		
	if positions_2d[index].size() == 4:	
		for ind in range(positions_2d[index].size()):
			if ind < positions_2d[index].size()-1:
				var vec = positions_2d[index][ind]
				# automatically draw lines
				var start = vec
				var end = positions_2d[index][ind+1]
				
				var line = bresenham_complex(start, end)
				for index in range (line.size()):
					for i in range(line[index].x, line[index].x+dot_size):
						for j in range(line[index].y, line[index].y+dot_size):
							# paranoia
							if i > 0 and i < 1000 and j > 0 and j < 1000:
								# necessary in 3.0
								image.lock()
								image.set_pixel(i,j, road)	
					
	else:		
		for ind in range(positions_2d[index].size()):
			if ind < positions_2d[index].size()-1:
			#print("Ind is " + str(ind) + " next ind is " + str(ind+1))	
				var vec = positions_2d[index][ind]
				# automatically draw lines
				var start = vec
				var end = positions_2d[index][ind+1]
				
				var line = bresenham_complex(start, end)
				for index in range (line.size()):
					for i in range(line[index].x, line[index].x+dot_size):
						for j in range(line[index].y, line[index].y+dot_size):
							# necessary in 3.0
							image.lock()
							image.set_pixel(i,j, linecolor)
							
# BRESENHAM
func swap(a,b):
	#print("Swapping " + String(a) + " and " + String(b))
	var c
	
	c = a
	a = b
	b = c
	return [a,b]

#translation of C version from https://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm
func bresenham_complex(start, end):
	#print("Running bresenham complex for " + String(start) + " to " + String(end))
	var points = PoolVector2Array()
	
	#helper vars
	var sx = start.x
	var sy = start.y
	var ex = end.x
	var ey = end.y
	
	#do we swap?
	var steep = abs(end.y - start.y) > abs(end.x - start.x)
	#print(String(steep))
	if (steep):
		#swap x,y for source
		var swap = swap(sx, sy)
		sx = swap[0]
		sy = swap[1]
		#swap x,y for end
		var swap_e = swap(ex, ey)
		ex = swap_e[0]
		ey = swap_e[1]
	
	#if start x is bigger than end x, swap them around to be able to run the normal algo
	if sx > ex:
		#swap x
		var swap_x = swap(sx, ex)
		sx = swap_x[0]
		ex = swap_x[1]

		#swap y
		var swap_y = swap(sy, ey)
		sy = swap_y[0]
		ey = swap_y[1]
		
	var deltax = ex - sx
	var deltay = abs(ey-sy)
	
	var error = deltax/2.0
	var ystep
	if sy < ey:
		ystep = 1
	else:
		ystep = -1

	var y = sy
	#print("Bresenham y " + String(y) + " x range: " + String(sx) + " " + String(ex))
	for x in range(sx, ex):
		if (steep):
			points.push_back(Vector2(y,x))
		else:
			points.push_back(Vector2(x,y))
			
		error -= deltay
		if error < 0:
			y = y + ystep
			error = error + deltax

	return points

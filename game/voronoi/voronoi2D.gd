tool
extends Node2D

# class member variables go here, for example:
var image
var data = []
var polys = []
var commons = []

func _ready():
	randomize()
	
	generate_voronoi_diagram_data(500, 500, 25)
	data_to_polygon()
	polygon_children()

	# get common points
	for i in range(polys.size()-1):
		var pts = get_common_points(i)
		
		# storing per poly lets us draw lines around
		commons.append(pts)

		
	#print("Commons " + str(commons))
	#clean_up_commons()

	
	poly_helper(commons)
	#print(str(commons))

#func set_textur():
#	get_node("Sprite").set_texture(load("res://VoronoiMap.png"))

func hypot(x,y):
	return sqrt(x*x + y*y)

func generate_voronoi_diagram_data(width, height, num_cells):
	var nx = []
	var ny = []
	
	for i in range(num_cells):
		# coords
		nx.append(rand_range(0, width))
		ny.append(rand_range(0, height))
		var cell = []
		data.append(cell)
	
	for y in range(height):
		for x in range(width):
			var dmin = hypot(width-1, height-1)
			var j = -1
			for i in range(num_cells):
				var d = hypot(nx[i]-x, ny[i]-y)
				if d < dmin:
					dmin = d
					j = i
			
	#for i in range(num_cells):
	#	if j = i:
			data[j].append(Vector2(x,y))
			
			#if 
			#debug.append(Vector3(x,y,j))	



func generate_voronoi_diagram_image(width, height, num_cells):
	image = Image.new()
	image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# necessary in 3.0
	image.lock()
	
	var imgx = image.get_size().x
	var imgy = image.get_size().y
	var nx = []
	var ny = []
	var nr = []
	var ng = []
	var nb = []
	for i in range(num_cells):
		# coords
		nx.append(rand_range(0, imgx))
		ny.append(rand_range(0, imgy))
		# colors
		nr.append(randf())
		ng.append(randf())
		nb.append(randf())
		
		var cell = []
		data.append(cell)
		
		#debug.append(i)
	
	
	for y in range(imgy):
		for x in range(imgx):
			var dmin = hypot(imgx-1, imgy-1)
			var j = -1
			for i in range(num_cells):
				var d = hypot(nx[i]-x, ny[i]-y)
				if d < dmin:
					dmin = d
					j = i
			
			# for debugging
			data[j].append(Vector2(x,y))

			# color
			image.set_pixel(x, y, Color(nr[j], ng[j], nb[j]))
	
	image.save_png("res://VoronoiMap.png")
	
	#var textur = ImageTexture.new().create_from_image(image)
	
	set_textur()
	
	#var textur = load("res://VoronoiMap.png")
	#get_node("Sprite").set_texture(textur)
	
func data_to_polygon():
	for c in data:
		#print("Polygonizing " + str(data.find(c)) + "...")
		var poly = Geometry.convex_hull_2d(c)
		
		# test
		#print("Reducing " + str(data.find(c)) + "...")
		var new_poly = reduce_poly(poly, 2)
		polys.append(new_poly)
		
		#print(str(poly))
		
		#polys.append(poly)
		
func reduce_poly(poly, threshold):
	var new_poly = Array(poly).duplicate() # can't iterate and remove
			
	var to_remove = []
	# size()-1 is normal, deduce 2 so that i-2 works:
	for i in poly.size()-3:
		# B-A = A to B
		var vec1 = poly[i+1]-poly[i]
		var vec2 = poly[i+2]-poly[i]
		var angle = vec2.angle_to(vec1) #radians
		#print("Angle diff " + str(abs(rad2deg(angle))) + " for i: " + str(i))
		
		# if angle is the same, remove middle point
		if abs(rad2deg(angle)) < threshold:
			#print("Removing point at: " + str(i+1) + " because angle is " + str(abs(rad2deg(angle))))
			
			to_remove.append(poly[i+1])
			# as we remove, the indices change
			#new_poly.remove(i+1)
	
	# remove specified
	for p in to_remove:
		new_poly.remove(new_poly.find(p))
	
	
	#print("New poly" + str(new_poly))
	#print("New poly: " + str(new_poly.size()))
		
	return new_poly	

func get_common_points(ind):
	#print("Getting common points for " + str(ind))
	var pts = []
	var temp = []
	
	for p in polys[ind]:
		#print("Polygon range starts at : " + str(ind+1))
		# for each of the other polygons
		for i in range(ind+1, polys.size()-1):
			for pt in polys[i]:
				if pt.distance_to(p) < 5 and not temp.has(p): # avoid duplicates
					#print("Found a point close to " + str(p) + " at : " + str(pt))
					pts.append([p, pt, ind, i])
					temp.append(p)
		
		# check earlier polys, just in case			
		if ind >= 2:
			for i in range(0, ind):
				for pt in polys[i]:
					if pt.distance_to(p) < 5 and not temp.has(p): # avoid duplicates
						#print("Found a point close to " + str(p) + " at : " + str(pt))
						pts.append([p, pt, ind, i])
						temp.append(p)
	#print(str(pts))		
	
	return pts
	
# currently cleans way too much
func clean_up_commons():
	var closest = []
	for p in commons:
		#print("p: " + str(p))
		for i in range(p.size()-1):
			find_closest(commons.find(p), i, closest)
	
	#print("Closest " + str(closest))
	
	
	for p in closest:
		for c in commons:
			if p[2] or p[3] == commons.find(c):
			#print("c:" + str(c) + " Looking for " + str(p))
			
				# paranoia = sometimes it doesn't find 
				var fnd = c.find(p)
				if fnd != -1:
					c.remove(fnd)
	
	#return closest

		
func find_closest(ind, i, closest):
	for a in range(i+1, commons.size()-1):
		for j in range(commons[a].size()-1):
			var p = commons[ind][i][0]
			var p2 = commons[a][j][0]
			if p.distance_to(p2) < 5:
				closest.append(commons[a][j])
	
	
	
func poly_helper(pts):
	var script = load("res://2d tests/voronoi_2d_helper.gd")
	var node = Node2D.new()
	node.set_script(script)
	add_child(node)
	node.pts = pts
		
func polygon_children():
	var script = load("res://2d tests/2d_polygon_corners.gd")
	for p in polys:
		var node = Polygon2D.new()
		var color = Color(randf(), randf(), randf(), 0.5)
		node.set_polygon(p)
		node.set_color(color)
		node.set_script(script)
		add_child(node)

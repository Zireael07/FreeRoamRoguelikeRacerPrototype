tool
extends Node

# class member variables go here, for example:
var data = []
var polys = []
var commons = []

var lines = []

func _ready():
	randomize()
	
	generate_voronoi_diagram_data(100, 100, 15) # used to be 500x500, 25
	data_to_polygon()
	#polygon_children()

	# get common points
	for i in range(polys.size()-1):
		var pts = get_common_points(i)
		
		# storing per poly lets us draw lines around
		commons.append(pts)
		
	#print("Commons " + str(commons))
	#clean_up_commons()
	
	get_lines()
	
	#print(str(lines))
	
	#print(str(commons))

# 3d only
func get_lines():
	for c in commons:
		for i in range (c.size()-2):
			var p1 = c[i]
			var p2 = c[i+1]
			
			# discard overly short
			if p1[0].distance_to(p2[0]) > 5:
				# B-A = A->B
				lines.append([p1[0], p2[0]])

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
			
			data[j].append(Vector2(x,y))
			
	
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

# old version	
func clean_up_commons():
	var closest = []
	for i in range(commons.size()-1):
		find_closest(i, closest)
	
	for p in closest:
		# paranoia = sometimes it doesn't find 
		var fnd = commons.find(p)
		if fnd != -1:
			commons.remove(fnd)
	
	#return closest

		
func find_closest(i, closest):
	for j in range(i+1, commons.size()-1):
		var p = commons[i]
		var p2 = commons[j]
		if p.distance_to(p2) < 5:
			closest.append(p2)
	

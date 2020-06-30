# this is the 2d demo
tool
extends CanvasItem

# Procedural algorithm for the generation of two-dimensional Poission-disc
# sampled ("blue") noise. For mathematical details, please see the blog
# article at https://scipython.com/blog/poisson-disc-sampling-in-python/
# Christian Hill, March 2017.

# class member variables go here, for example:
# Choose up to k points around each reference point as candidates for a new
# sample point
var k = 20

# Minimum distance between samples
var r = 50

var width = 200
var height = 250

# Cell side length
var a = r / sqrt(2)
# Number of cells in the x- and y-directions of the grid
var nx = int(width / a) + 1 
var ny = int(height / a) + 1

# A list of coordinates in the grid of cells
var coords_list = []
# Initilalize the dictionary of cells: each key is a cell's coordinates, the
# corresponding value is the index of that cell's point's coordinates in the
# samples list (or None if the cell is empty).
var cells = {}
var samples = [] # a list of lists (we don't use Vector2 here for speed)

var edges = []

var out_edges = []

#export var seede = 3046862638 setget set_seed
var seede = 10000001 #3046862638


func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here

	# randomize the seed
	#randomize()
	#var s = randi()
	#set_seed(s)
	#seede = s
	#seed(seede)
	#run()
	
	set_seed(seede)


func set_seed(value):
	if Engine.is_editor_hint():
		print("Seed value is " + str(value))
	# if not set_get we don't need this
	#if !Engine.editor_hint:
	#yield(self, 'tree_entered')
	
	for ix in range(nx):
		for iy in range(ny):
			coords_list.append([ix, iy])
	
	for coords in coords_list:
		# we can't use straightforward coords as key :(
		var key = Vector2(coords[0], coords[1])
		# we can't store null as value, so...
		cells[key] = -1
	
	seed(value)
	#rand_seed(value)
	run()
	
	# sort
	#var closest = sort_distance()
	
	# convex (outline)
	var vec2 = []
	for s in samples:
		vec2.append(Vector2(s[0], s[1]))
		
	var conv = Geometry.convex_hull_2d(vec2)
	print("Convex hull: " + str(conv))

	#convex_pos_to_edge_indices(conv)

	# this gives list of Vec2 (positions)
	for i in range(0, conv.size()-1):
		var ed = [conv[i], conv[i+1]]
		out_edges.append(ed)
	
	#print("Seed " + str(seede))

func convex_pos_to_edge_indices(conv):
	#print("Convex: " + str(conv))
	#print("Samples: " + str(samples))
	for i in range(0, conv.size()-1):
		var pt = conv[i]
		#print("pt: " + str(pt))
		#print("pt list: " + str([pt.x, pt.y]))
		#var id = samples.find([pt.x, pt.y])
		var id = -1
		for j in range(0, samples.size()-1):
			var s = samples[j]
			# fudge needed for some reason
			if s[0]-pt.x < 0.001 and s[1]-pt.y < 0.001:
				id = j
				break # break the loop
		
		#print(id)
		
		var pt2 = conv[i+1]
		#var id2 = samples.find([pt2.x, pt2.y])
		var id2 = -1
		for j in range(0, samples.size()-1):
			var s = samples[j]
			#if s[0] == pt.x and s[1] == pt.y:
			# fudge needed for some reason
			if s[0]-pt2.x < 0.001 and s[1]-pt2.y < 0.001:
				id2 = j
				break # break the loop
		
		#print(id2)
		var ed = [id, id2]
		out_edges.append(ed)

	# consistency check
	if out_edges[0][0] != out_edges[out_edges.size()-1][1]:
		print("Something was wrong in the edges calc!")

func sort_distance(tg = Vector2(0,0)):
	var dists = []
	var tmp = []
	var closest = []

	for i in range(0, samples.size()-1):
		var s = samples[i]
		var dist = s-tg
		tmp.append([dist, i])
		dists.append(dist)

	dists.sort()

	var max_s = tmp.size()

	for i in range(0, max_s):
		#print("Running add, attempt " + str(i))
		#print("tmp: " + str(tmp))
		for t in tmp:
			#print("Check t " + str(t))
			if t[0] == dists[0]:
				closest.append(t)
				tmp.remove(tmp.find(t))
				# key line
				dists.remove(0)
				#print("Adding " + str(t))
	# if it's not empty by now, we have an issue
	#print(tmp)

	print("Sorted inters: " + str(closest))

	return closest


# ------------------------------------

func choice(list):
	var i = randi() % list.size()
	return i #list[i]


func get_cell_coords(pt):
	"""Get the coordinates of the cell that pt = (x,y) falls in."""

	return [int(pt[0] / a), int(pt[1] / a)]


func get_neighbours(coords):
	"""Return the indexes of points in cells neighbouring cell at coords.

	For the cell at coords = (x,y), return the indexes of points in the cells
	with neighbouring coordinates illustrated below: ie those cells that could
	contain points closer than r.

									 ooo
									ooooo
									ooXoo
									ooooo
									 ooo

	"""

	var dxdy = [Vector2(-1, -2), Vector2(0, -2), Vector2(1, -2), Vector2(-2, -1), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(2, -1), 
			Vector2(-2, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(2, 0), Vector2(-2, 1), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1),
			Vector2(-1, 2), Vector2(0, 2), Vector2(1, 2), Vector2(0, 0)]
	var neighbours = []
	for v in dxdy:
		var dx = v.x
		var dy = v.y
		var neighbour_coords = [coords[0] + dx, coords[1] + dy]
		if (0 <= neighbour_coords[0] and neighbour_coords[0] < nx and
				0 <= neighbour_coords[1] and neighbour_coords[1] < ny):
			# We're off the grid: no neighbours here.
			# those were making us stuck in the loop, so I negated the above statement
			#continue
			
			var key = Vector2(neighbour_coords[0], neighbour_coords[1])
			var neighbour_cell = cells[key]
			if neighbour_cell != -1:
				# This cell is occupied: store this index of the contained point.
				neighbours.append(neighbour_cell)
	return neighbours


func point_valid(pt, samples):
	"""Is pt a valid point to emit as a sample?

	It must be no closer than r from any other point: check the cells in its
	immediate neighbourhood.

	"""

	var cell_coords = get_cell_coords(pt)
	for idx in get_neighbours(cell_coords):
		var nearby_pt = samples[idx]
		# Squared distance between or candidate point, pt, and this nearby_pt.
		var distance2 = pow((nearby_pt[0] - pt[0]), 2) + pow((nearby_pt[1] - pt[1]), 2)
		if distance2 < pow(r, 2):
			# The points are too close, so pt is not a candidate.
			return false
	# All points tested: if we're here, pt is valid
	return true


func get_point(k, refpt, samples):
	"""Try to find a candidate point relative to refpt to emit in the sample.

	We draw up to k points from the annulus of inner radius r, outer radius 2r
	around the reference point, refpt. If none of them are suitable (because
	they're too close to existing points in the sample), return False.
	Otherwise, return the pt.

	"""
	var i = 0
	while i < k:
		var rho = rand_range(r, 2 * r)
		var theta = rand_range(0, 2 * PI)
		var pt = [refpt[0] + rho * cos(theta), refpt[1] + rho * sin(theta)]
		if (0 < pt[0] and pt[0] < width and 0 < pt[1] and pt[1] < height):
			# This point falls outside the domain, so try again.
			#continue
			if point_valid(pt, samples):
				return pt
		i += 1
	# We failed to find a suitable point in the vicinity of refpt.
	return false

func run():
	# Pick a random point to start with.
	var pt = [rand_range(0, width), rand_range(0, height)]
	samples = [pt]
	# Our first sample is indexed at 0 in the samples list...
	var coords = get_cell_coords(pt)
	#var key = coords[0] + coords[1] * nx
	var key = Vector2(coords[0], coords[1])
	cells[key] = 0
	# ... and it is active, in the sense that we're going to look for more points
	# in its neighbourhood.
	var active = [0]
	
	var nsamples = 1
	# As long as there are points in the active list, keep trying to find samples.
	while active:
		# choose a random "reference" point from the active list.
		#var idx = random.choice(active)
		var idx = choice(active)
		#print("Idx: " + str(idx))
		var refpt = samples[idx]
		# Try to pick a new point relative to the reference point.
		pt = get_point(k, refpt, samples)
		if pt:
			# add to edges
			#edges.append([refpt, pt])
			
			
			# Point pt is valid: add it to the samples list and mark it as active
			samples.append(pt)
			nsamples += 1
			active.append(samples.size() - 1)
			coords = get_cell_coords(pt)
			#key = coords[0] + coords[1] * nx
			key = Vector2(coords[0], coords[1])
			cells[key] = samples.size() -1
			
			#add indices to edges
			# because the new point is always appended at the end
			edges.append([idx, samples.size()-1])
			
		else:
			# We had to give up looking for valid points near refpt, so remove it
			# from the list of "active" points.
			#if active.size() > idx:
			active.remove(idx)
	
	#print(samples)
	return samples
	
func _draw():
	#pass
	for i in range(0, samples.size()):
		var p = samples[i]
		if i == 0:
			draw_circle(Vector2(p[0], p[1]), 2.0, Color(0,1,0))
		else:
			draw_circle(Vector2(p[0], p[1]), 2.0, Color(1,0,0))

	for e in out_edges:
		draw_line(e[0], e[1], Color(1,0,1))
	

	for e in edges:
		var p1 = samples[e[0]]
		var p2 = samples[e[1]]
		draw_line(Vector2(p1[0], p1[1]), Vector2(p2[0], p2[1]), Color(0,0,1))
		#draw_line(Vector2(e[0][0], e[0][1]), Vector2(e[1][0], e[1][1]), Color(0,0,1))
	

	# changing type to CanvasItem fixes this but breaks instancing
	update()

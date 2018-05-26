tool
extends Node2D

# class member variables go here, for example:
var image
# var b = "textvar"

func _ready():
	randomize()
	
	if not load("res://VoronoiMap.png"):
		generate_voronoi_diagram(500, 500, 25)
	else:
		set_textur()
	#	get_node("Sprite").set_texture(load("res://VoronoiMap.png"))
	
	# not enough, it takes too much time to import
	#call_deferred("set_textur")

func set_textur():
	get_node("Sprite").set_texture(load("res://VoronoiMap.png"))

func hypot(x,y):
	return sqrt(x*x + y*y)

func generate_voronoi_diagram(width, height, num_cells):
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
		nx.append(rand_range(0, imgx))
		ny.append(rand_range(0, imgy))
		nr.append(randf())
		ng.append(randf())
		nb.append(randf())
	for y in range(imgy):
		for x in range(imgx):
			var dmin = hypot(imgx-1, imgy-1)
			var j = -1
			for i in range(num_cells):
				var d = hypot(nx[i]-x, ny[i]-y)
				if d < dmin:
					dmin = d
					j = i
			image.set_pixel(x, y, Color(nr[j], ng[j], nb[j]))
	
	image.save_png("res://VoronoiMap.png")
	
	#var textur = ImageTexture.new().create_from_image(image)
	
	set_textur()
	
	#var textur = load("res://VoronoiMap.png")
	#get_node("Sprite").set_texture(textur)
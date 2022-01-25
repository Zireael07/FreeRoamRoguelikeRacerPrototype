@tool
extends Node

# class member variables go here, for example:
var pts = []
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _draw():
	if pts.size() > 0:
		# draw common points
		for c in pts:
			for p in c:
				draw_circle(p[0], 3.0, Color(1,0,0))
		
		# draw lines between common points
		for c in pts:
			#print("Drawing lines for " + str(pts.find(c)) + "...")	
			for i in range (c.size()-2):
				var p1 = c[i]
				var p2 = c[i+1]
				# if they belong to same poly
				#if p1[1] == p2[1]: #or p1[2] == p2[2]: #or p1[2] == p2[1] or p1[1] == p2[2]:
				draw_line(p1[0], p2[0], Color(0,1,0))

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

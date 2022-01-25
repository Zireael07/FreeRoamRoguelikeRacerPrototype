@tool
extends Polygon2D

# Declare member variables here. Examples:
var poly = []

# Called when the node enters the scene tree for the first time.
func _ready():
	poly.resize(0)
	#print(str(get_polygon()))
	
	#get_polygon().reverse()
	#print(str(get_polygon()))
	
	for i in range(get_polygon().size()):
		var p = get_polygon()[i]
		poly.append(Vector2(p.x-600, p.y))
	
	#print(str(poly))
	poly = swap_arr(poly)
	#print(str(poly))
	
	poly = rotate_arr(poly, 3)
	#print(str(poly))
	
	#pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# based on https://www.geeksforgeeks.org/reverse-an-array-in-java/
#function swaps the array's first element with last element,  
#      second element with last second element and so on
func swap_arr(arr):
	var n = arr.size()
	for i in range(0, arr.size()/2):
		var t = arr[i]; 
		arr[i] = arr[n - i - 1]; 
		arr[n - i - 1] = t;
					
	return arr

# super naive!
# https://www.geeksforgeeks.org/python-program-right-rotate-list-n/
func rotate_arr(arr, num):
	var output_list = []
	# Will add values from n to the new list 
	for i in range(arr.size() - num, arr.size()): 
		output_list.append(arr[i]) 
	  
	# Will add the values before 
	# n to the end of new list     
	for i in range(0, arr.size() - num):  
		output_list.append(arr[i])
	
	return output_list

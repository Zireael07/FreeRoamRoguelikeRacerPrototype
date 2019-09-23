tool
extends Polygon2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var arr = [Vector2(-91.75, 240.375), Vector2(-355, 284.25), Vector2(-486.625, 338.25), Vector2(-530.5, 395.625), Vector2(-544, 496.875), 
	Vector2(-523.75, 601.5), Vector2(-338.125, 598.125), Vector2(-338.125, 527.25), Vector2(-321.25, 459.75), Vector2(-226.75, 402.375),
	Vector2(-142.375, 412.5), Vector2(-64.75, 503.625), Vector2(-44.5, 601.5), Vector2(752, 594.75), Vector2(782.380005, 469.875), 
	Vector2(843.119995, 422.625), Vector2(927.5, 419.25), Vector2(1018.619995, 466.5), Vector2(1065.880005, 574.5), Vector2(1173.880005, 554.25), 
	Vector2(1173.880005, 422.625), Vector2(1153.619995, 385.5), Vector2(1163.75, 307.875), Vector2(1136.75, 257.25), Vector2(964.619995, 118.875), 
	Vector2(978.119995, 88.5), Vector2(839.75, 71.625), Vector2(451.619995, 58.125), Vector2(218.75, 88.5)]

	rotate_arr_left(arr, 5)
	#print(arr)
	
	set_polygon(arr)
	
	# output
	var out = []
	for i in range(arr.size()):
		out.append(Vector2(arr[i].x/1000, (arr[i].y-601.5)/1000))
		
	print(out)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

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

func rotate_arr_left(arr, num):
	#Rotate the given array by n times toward left    
	for i in range(0, num):    
		#Stores the first element of the array    
		var first = arr[0];    
		
		for j in range(0, arr.size()-1):    
			#Shift element of array by one    
			arr[j] = arr[j+1];    
			
		#First element of array will be added to the end    
		arr[arr.size()-1] = first;
		
		
	return arr	
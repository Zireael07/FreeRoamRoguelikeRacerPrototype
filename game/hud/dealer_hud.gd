extends Control

# class member variables go here, for example:
var player

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	get_node("MoneyLabel").set_text(str(player.money))
	
func _on_Button_pressed():
	print("Going back to the city...")
	
	get_parent().go_back()
	
	#pass # replace with function body


func _on_ButtonLeft_pressed():
	if get_parent().get_node("car").is_visible():
		get_parent().get_node("car").hide()
		get_parent().get_node("bike").show()
	elif get_parent().get_node("bike").is_visible():
		get_parent().get_node("bike").hide()
		get_parent().get_node("car").show()
	#pass # Replace with function body.


func _on_ButtonRight_pressed():
	if get_parent().get_node("car").is_visible():
		get_parent().get_node("car").hide()
		get_parent().get_node("bike").show()
	elif get_parent().get_node("bike").is_visible():
		get_parent().get_node("bike").hide()
		get_parent().get_node("car").show()
	#pass # Replace with function body.

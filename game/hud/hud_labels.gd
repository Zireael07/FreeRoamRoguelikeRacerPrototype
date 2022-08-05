extends Control
 

# class member variables go here, for example:
@onready var label = get_node(^"Label")
@onready var debug_label = get_node(^"DebugAI/Label_info")
@onready var fps_label = get_node(^"Label FPS")
@onready var dist_label = get_node(^"Label dist")
@onready var road_label = get_node(^"Label road")
@onready var label_timer = get_node(^"Label timer")
@onready var label_clock = get_node(^"Label clock")
@onready var compass_label = get_node(^"CompassLabel")

# wheel/turn debug
@onready var label_angle = get_node(^"WheelAngle")
@onready var angle_bar = get_node(^"WheelAngleBar")
@onready var angle_limit_bar = get_node(^"WheelAngleBar2")

@onready var money_label = get_node(^"DriverInfo/MoneyLabel")

@onready var health_bar = get_node(^"Health")
@onready var battery_bar = get_node(^"Battery")

@onready var cam_control = get_node(^"CAM blink")
@onready var seed_label = get_node(^"SeedLabel")

@onready var nav_label = get_node(^"NavLabel")

var fps
var draws
var vertices

var regex

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	regex = RegEx.new()
	regex.compile("\\d{1,3}(?=(\\d{3})*$)")
	
	print("Found: ", regex.search("123456"))
	
	pass

func update_speed(text, clr):
	label.set_text(text)
	label.set_modulate(clr)

func update_debug(text):
	debug_label.set_text(text)
	
func append_debug(text):
	var txt = debug_label.get_text()
	debug_label.set_text(txt + text)	

func format_verts(text):
	# for strings, this is length() not size()!
	if text.length() > 3:
		# add space separator
		var n_txt = ""
		
		var matches = regex.search_all(text)
		for i in matches:
			n_txt += i.get_string() + " "
		#	print(i.get_string())
		
		# we don't have an array
		#var joined_string = PackedStringArray(matches).join(" ")
		#print(n_txt)
		
		text = n_txt
		
	return text
	
func update_fps():
	fps = str(Engine.get_frames_per_second()) + " ms: %.3f" % (1000.0/Engine.get_frames_per_second())
	draws = str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)) 
	vertices = str(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	fps_label.set_text(fps+ " draw calls" + draws + " verts: " + format_verts(vertices))

func update_distance(text):
	dist_label.set_text(text)
	
func update_road(text):
	road_label.set_text(text)	
	
func update_timer(text):
	label_timer.set_text("Timer: " + text)
	
func update_clock(text):
	label_clock.set_text(text)

func update_angle_limiter(val):
	angle_limit_bar.set_value((val/1)*100)

func update_wheel_angle(val, maxx):
	label_angle.set_text(str(rad2deg(val)))
	#var perc = 
	#print("Calc: " + str(perc))
	angle_bar.set_value((val/maxx)*100)

func update_compass(val):
	compass_label.set_text(val)
	
func update_money(val):
	money_label.set_text("Money:   " + str(val))
	
func update_health(val):
	health_bar.set_value(val)
	
func update_battery(val):
	battery_bar.set_value(val)
	
func update_seed(val):
	seed_label.set_text("Seed: " + str(val))

# for changing HUD between chase and cockpit cams
func toggle_cam(boo):
	cam_control.set_visible(boo)

func speed_chase():
	label.set_position(Vector2(25, -22))
	
func speed_cockpit():
	label.set_position(Vector2(425, 392))	

func update_nav_label(val):
	nav_label.set_text(val)
	
# ----------------------------------
func setup_vis(node, num_rays, y=100):
	get_node(node).columns = num_rays
	while get_node(node).get_child_count() < num_rays:
		var r = get_node(node+"/DebugRect").duplicate()
		get_node(node).add_child(r)
	
	# wait so that the container has its final size
	await get_tree().process_frame
	get_node(node).get_parent().get_node("Label2")._set_position(Vector2(get_node(node).get_size().x/4, y))
	get_node(node).get_parent().get_node("Label3")._set_position(Vector2(get_node(node).get_size().x/2, y))
	get_node(node).get_parent().get_node("Label4")._set_position(Vector2(get_node(node).get_size().x, y))

func update_AI_vis(ai):
	get_node("DebugAI/AI steering vis").danger = ai.danger
	get_node("DebugAI/AI steering vis").interest = ai.interest
	get_node("DebugAI/AI steering vis").update_vis()

func update_debug_stuff(data, rays):
	get_node("Debug").data = data
	get_node("Debug").rays = rays

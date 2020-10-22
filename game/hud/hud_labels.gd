extends Control
 

# class member variables go here, for example:
onready var label = get_node("Label")
onready var debug_label = get_node("Label 2")
onready var fps_label = get_node("Label FPS")
onready var dist_label = get_node("Label dist")
onready var road_label = get_node("Label road")
onready var label_timer = get_node("Label timer")
onready var label_clock = get_node("Label clock")
onready var compass_label = get_node("CompassLabel")

# wheel/turn debug
onready var label_angle = get_node("WheelAngle")
onready var angle_bar = get_node("WheelAngleBar")
onready var angle_limit_bar = get_node("WheelAngleBar2")

onready var money_label = get_node("DriverInfo/MoneyLabel")

onready var health_bar = get_node("Health")
onready var battery_bar = get_node("Battery")

onready var cam_control = get_node("CAM blink")
onready var seed_label = get_node("SeedLabel")

onready var nav_label = get_node("NavLabel")

var fps
var draws
var vertices


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	pass

func update_speed(text, clr):
	label.set_text(text)
	label.set_modulate(clr)

func update_debug(text):
	debug_label.set_text(text)
	
func update_fps():
	fps = str(Engine.get_frames_per_second()) + " ms: %.3f" % (1000.0/Engine.get_frames_per_second())
	draws = str(Performance.get_monitor(Performance.RENDER_DRAW_CALLS_IN_FRAME)) 
	vertices = str(Performance.get_monitor(Performance.RENDER_VERTICES_IN_FRAME))
	fps_label.set_text(fps+ " draw calls" + draws + " verts: " + vertices)

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
	

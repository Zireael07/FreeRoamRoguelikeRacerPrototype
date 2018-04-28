extends Control
 

# class member variables go here, for example:
var label = null
var debug_label = null
var fps_label = null
var dist_label = null
var label_timer = null
var label_clock = null
var label_angle = null
var angle_bar = null
var angle_limit_bar = null

var health_bar = null

var fps
var draws
var vertices


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	label = get_node("Label")
	debug_label = get_node("Label 2")
	fps_label = get_node("Label FPS")
	dist_label = get_node("Label dist")
	label_timer = get_node("Label timer")
	label_clock = get_node("Label clock")
	label_angle = get_node("WheelAngle")
	angle_bar = get_node("WheelAngleBar")
	angle_limit_bar = get_node("WheelAngleBar2")
	health_bar = get_node("Health")

func update_speed(text):
	label.set_text(text)

func update_debug(text):
	debug_label.set_text(text)
	
func update_fps():
	fps = str(Engine.get_frames_per_second()) + " ms: %.3f" % (1000.0/Engine.get_frames_per_second())
	draws = str(Performance.get_monitor(Performance.RENDER_DRAW_CALLS_IN_FRAME)) 
	vertices = str(Performance.get_monitor(Performance.RENDER_VERTICES_IN_FRAME))
	fps_label.set_text(fps+ " draw calls" + draws + " verts: " + vertices)

func update_distance(text):
	dist_label.set_text(text)
	
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
	
func update_health(val):
	health_bar.set_value(val)
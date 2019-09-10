extends TextureRect

var val=Vector2(0,0)

var touch_index = -1
var minXY
var maxXY
var isVertical

var joystick
var valOut
#var valOut2

var halfX
var halfY


func _ready():
	set_process_input(true)
	joystick=get_node("Joystick")
	
	valOut=get_node("../valV")
	
	# centers x = floor(float(get_size().x))/2.0)
	
	minXY=Vector2(0,0)
	maxXY = get_size()
	# the -1 made it impossible to get -1,-1 output values
	#maxXY=Vector2(get_size().x-1,get_size().y-1)
	
	#print("max XY: " +str(maxXY))
	#print("joystick size: " + str(joystick.get_size()))
	#print("get size:" + str(get_size()))
	
	# reduce lookups
	halfX = get_size().x/2
	halfY = get_size().y/2
	
	
#	isVertical=(get_name().left(1)=="V")
#
#	if isVertical: #vertical joystick?
#		minXY=Vector2(floor((float(get_size().x))/2.0),0)
#		maxXY=Vector2(floor((float(get_size().x))/2.0),get_size().y-1)
#		valOut=get_node("../valV")
#	else: #horizontal joystick
#		minXY=Vector2(0,floor((float(get_size().y))/2.0))
#		maxXY=Vector2(get_size().x-1,floor((float(get_size().y))/2.0))
#		valOut=get_node("../valH")
	
			
func _input(ev):
	if is_visible() and \
		((ev is InputEventMouseMotion)):
		#((ev is InputEventMouseButton) or (ev is InputEventMouseMotion)):
		#((ev is InputEventScreenTouch) or (ev is InputEventScreenDrag)):
			
		#if ev is InputEventScreenTouch:
#		if ev is InputEventMouseButton:
#			if ev.pressed:
#				var p = get_position()
#				var sz = get_size()
#				#check if touch was inside control
#				if (ev.position.x>=p.x) and (ev.position.x<p.x+sz.x) and (ev.position.y>=p.y) and (ev.position.y<p.y+sz.y):
#					#save touch index to track "DRAG" events
#				#	touch_index = ev.index
#					ev.position.x=clamp(ev.position.x-p.x,minXY.x,maxXY.x)
#					ev.position.y=clamp(ev.position.y-p.y,minXY.y,maxXY.y)
#					set_val(ev)
#			else: #release
#				#if touch_index == ev.index:
#				#	touch_index=-1
#					reset_val(ev)
		
		if ev is InputEventMouseMotion:				
		#if ev is InputEventScreenDrag:
			var p = get_position()
			var sz = get_size()
			#if (ev.index == touch_index): #allow drag outside of control
			ev.position.x=clamp(ev.position.x-p.x,minXY.x,maxXY.x)
			ev.position.y=clamp(ev.position.y-p.y,minXY.y,maxXY.y)
			set_val(ev)
				
#reset joystick to center (on touch release)
func reset_val(ev):
	ev.position.x=(maxXY.x-minXY.x+1)/2+minXY.x
	ev.position.y=(maxXY.y-minXY.y+1)/2+minXY.y
	set_val(ev)

#set value based on control-relative event coordinates (also suitable for mouse coords)
func set_val(ev):
	# remove vert/horizontal distinction
#	if isVertical:
#		val = clamp((ev.position.y-(get_size().y/2.0))/(get_size().y/-2.0),-1,1)
#	else:
#		val = clamp((ev.position.x-(get_size().x/2.0))/(get_size().x/-2.0),-1,1)



	# clamp
	#print("event pos: " + str(ev.position) + str(offset))
	
	# doesn't quite work
	#var clampx = offset.x/(joystick.get_size().x/-2.0)
	#var clampy = offset.y/(joystick.get_size().y/-2.0)
	
	#var clampx = (ev.position.x-halfX)/(get_size().x/-2.0)
	#var clampy = (ev.position.y-halfY)/(get_size().y/-2.0)
	
	# reduced lookups AND more understandable
	var clampx = (ev.position.x-halfX)/-halfX
	var clampy = (ev.position.y-halfY)/-halfY
	
	#print("clampx: " + str(clampx) + " clampy: " + str(clampy))
	# based on originals
	#val.x = clamp((ev.position.x-get_size().x/2.0), -1, 1)
	#val.y = clamp((ev.position.y-get_size().y/2.0), -1, 1)
	
	val.x = clamp(clampx, -1, 1)
	val.y = clamp(clampy, -1, 1)
	
	#move joystick control
	# offset from center
	var offset = Vector2(ev.position.x-(joystick.get_size().x/2), ev.position.y-(joystick.get_size().y/2))
	joystick.set_position(offset)
	
	# color the joy based on input
	if abs(val.x) > 0.85:
		joystick.set_modulate(Color(1,0,0,1))
	elif abs(val.x) > 0.5:
		joystick.set_modulate(Color(1,1,0,1))
	elif abs(val.x) < 0.1: # deadzone, no tint
		joystick.set_modulate(Color(0,0,0,1))
	else:
		joystick.set_modulate(Color(0,1,0,1))
	
	
	# output steering value debug
	valOut.set_text(str(val))
extends Sprite

#update uniforms

#onready var global_v=get_tree().get_root().get_node("scene")
onready var global_v = get_tree().get_nodes_in_group("root")[0]

func _ready():
	pass
#
#func _process(delta):
#	self.material.set("shader_param/iTime",global_v.iTime)
#	self.material.set("shader_param/iFrame",global_v.iFrame)
#	#get_parent()._trigger_update_sky()

func set_coverage(value):
	self.material.set("shader_param/COVERAGE",float(value)/100)
	get_parent().get_parent()._trigger_update_sky()

func set_absorbtion(value):
	self.material.set("shader_param/ABSORPTION",float(value)/10)
	get_parent().get_parent()._trigger_update_sky()

func set_thickness(value):
	self.material.set("shader_param/THICKNESS",value)
	get_parent().get_parent()._trigger_update_sky()

# new
func set_cloud_tint(value):
	self.material.set("shader_param/HORIZON_COL", value)
	#get_parent().get_parent()._trigger_update_sky()

func set_tint_dist(value):
	self.material.set("shader_param/TINT_DIST", value)
	#get_parent().get_parent()._trigger_update_sky()


func step_scb(value):
	self.material.set("shader_param/STEPS",value)
	get_parent().get_parent()._trigger_update_sky()
	

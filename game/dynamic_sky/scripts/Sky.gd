extends Sprite

#udate uniforms

#onready var global_v=get_tree().get_root().get_node("scene")
onready var global_v = get_tree().get_nodes_in_group("root")[0]

func _ready():
	pass
#
#func _process(delta):
#	self.material.set("shader_param/iTime",global_v.iTime)
#	self.material.set("shader_param/iFrame",global_v.iFrame)
#	#get_parent()._trigger_update_sky()

func cov_scb(value):
	self.material.set("shader_param/COVERAGE",float(value)/100)
	get_parent()._trigger_update_sky()

func absb_scb(value):
	self.material.set("shader_param/ABSORPTION",float(value)/10)
	get_parent()._trigger_update_sky()

func thick_scb(value):
	self.material.set("shader_param/THICKNESS",value)
	get_parent()._trigger_update_sky()

func step_scb(value):
	self.material.set("shader_param/STEPS",value)
	get_parent()._trigger_update_sky()
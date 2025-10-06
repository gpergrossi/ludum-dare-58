class_name CameraHide extends StaticBody3D

var hidden := false
var last_hide := 0

@export var the_mesh: MeshInstance3D

func do_hide() -> void:
	the_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	last_hide = Time.get_ticks_msec()
	hidden = true

func do_show() -> void:
	the_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	hidden = false

func _process(_delta: float) -> void:
	var time := Time.get_ticks_msec()
	if hidden and time - last_hide > 1000:
		do_show()

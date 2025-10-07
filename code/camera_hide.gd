class_name CameraHide extends StaticBody3D

const RESHOW_TIMER := 250

var hidden := false
var last_hide := 0

@export var the_mesh: MeshInstance3D
@export var another_mesh: MeshInstance3D
@export var more_meshes: Array[MeshInstance3D]

func do_hide() -> void:
	if the_mesh:
		the_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	if another_mesh:
		another_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	if more_meshes and not more_meshes.is_empty():
		for mesh in more_meshes:
			if mesh:
				mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
				
	last_hide = Time.get_ticks_msec()
	hidden = true

func do_show() -> void:
	if the_mesh:
		the_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if another_mesh:
		another_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if more_meshes and not more_meshes.is_empty():
		for mesh in more_meshes:
			if mesh:
				mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	hidden = false

func _process(_delta: float) -> void:
	var time := Time.get_ticks_msec()
	if hidden and ((time - last_hide) > RESHOW_TIMER):
		do_show()

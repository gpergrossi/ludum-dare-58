extends ProgressBar

var small_collected := 0
var small_total := 0
var medium_collected := 0
var medium_total := 0

@export var panel_container: PanelContainer
@export var victory_particles: CPUParticles2D

signal true_completion()

func _on_med_props_on_props_changed(collected: int, total: int) -> void:
	medium_collected = collected
	medium_total = total
	refresh()

func _on_clutter_system_small_props_changed(collected: int, total: int) -> void:
	small_collected = collected
	small_total = total
	refresh()

func refresh():
	max_value = small_total + medium_total * 10
	value = small_collected + medium_collected * 10
	if value == max_value:
		if panel_container:
			var stylebox := panel_container.get_theme_stylebox("panel").duplicate()
			panel_container.remove_theme_stylebox_override("panel")
			stylebox.border_color = Color.WHITE
			panel_container.add_theme_stylebox_override("panel", stylebox)
			true_completion.emit()
			victory_particles.emitting = true

class_name LabelDust extends Label

const display_scale := 1.0 / 10.0

func _on_player_dust_changed(current: float, capacity: float) -> void:
	text = str(roundi(current * display_scale)) + " / " + str(roundi(capacity * display_scale))

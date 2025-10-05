class_name DustBar extends ProgressBar

func _on_player_dust_changed(current: float, capacity: float) -> void:
	value = current
	max_value = capacity

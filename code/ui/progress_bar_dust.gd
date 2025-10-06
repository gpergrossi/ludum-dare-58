class_name DustBar extends Range

func _on_player_dust_changed(current: float, capacity: float) -> void:
	value = minf(current + 25, capacity)
	max_value = capacity

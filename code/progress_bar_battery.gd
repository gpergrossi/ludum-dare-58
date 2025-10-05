extends ProgressBar


func _on_player_charge_changed(current: float, max: float) -> void:
	value = current
	max_value = max

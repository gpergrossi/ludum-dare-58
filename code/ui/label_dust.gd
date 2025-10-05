extends Label

func _on_player_dust_changed(current: float, capacity: float) -> void:
	text = str(roundi(current)) + " / " + str(roundi(capacity))

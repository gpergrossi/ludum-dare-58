extends Label


func _on_player_charge_changed(current: float, max: float) -> void:
	text = str(roundi(current)) + " / " + str(roundi(max))

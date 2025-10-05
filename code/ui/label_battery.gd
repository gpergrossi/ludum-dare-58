extends Label


func _on_player_charge_changed(current: float, max_: float) -> void:
	text = str(roundi(current)) + " / " + str(roundi(max_))

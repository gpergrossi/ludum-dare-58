extends Label

func _on_dirt_world_3d_on_dust_initialized(total: int) -> void:
	text = "0 / " + str(total)

func _on_dirt_world_3d_on_dust_collected(collected: int, total: int) -> void:
	text = str(collected) + " / " + str(total)

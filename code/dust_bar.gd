class_name DustBar extends ProgressBar

func _on_dirt_world_3d_on_dust_initialized(total: int) -> void:
	max_value = total

func _on_dirt_world_3d_on_dust_collected(collected: int, total: int) -> void:
	value = collected
	max_value = total

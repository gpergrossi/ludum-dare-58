extends PanelContainer

func _on_button_ok_pressed() -> void:
	self.visible = false


func _on_progress_bar_cleanliness_true_completion() -> void:
	self.visible = true

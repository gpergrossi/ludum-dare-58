class_name ButtonHighlight extends Panel

const transp := Color(Color.WHITE, 0.0)
const period := 2.0

var timer := 0.0

@export var enabled := false:
	set(e):
		enabled = e
		if not enabled:
			self_modulate = Color.TRANSPARENT
			timer = 0.0

func _process(delta: float) -> void:
	timer += delta
	if enabled:
		self_modulate = Color.WHITE.lerp(transp, cos((timer / period) * TAU) * 0.5 + 0.5)

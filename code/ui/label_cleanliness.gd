extends Label

var small_collected := 0
var small_total := 0
var medium_collected := 0
var medium_total := 0

func _on_med_props_on_props_changed(collected: int, total: int) -> void:
	medium_collected = collected
	medium_total = total
	refresh()

func _on_clutter_system_small_props_changed(collected: int, total: int) -> void:
	small_collected = collected
	small_total = total
	refresh()

func refresh():
	text = "Total Cleanliness: " + str(clampi(floori(100.0 * float(small_collected + medium_collected * 10) / float(small_total + medium_total * 10)), 0, 100)) + "%"

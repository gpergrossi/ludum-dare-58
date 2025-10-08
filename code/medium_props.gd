class_name MediumProps extends Node3D

var total_medium_props := 0
var medium_props_collection := 0

signal on_props_changed(collected: int, total: int)

func _ready() -> void:
	if not child_exiting_tree.is_connected(on_child_exited):
		child_exiting_tree.connect(on_child_exited)
	for child in get_children():
		if child is StaticBodyGamePiece:
			total_medium_props += 1
	on_props_changed.emit(medium_props_collection, total_medium_props)

func on_child_exited(_child: Node) -> void:
	medium_props_collection += 1
	on_props_changed.emit(medium_props_collection, total_medium_props)

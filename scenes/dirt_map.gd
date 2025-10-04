class_name DirtMap extends MeshInstance3D

@export var player_position: Vector3

@onready var size := (mesh as PlaneMesh).size
@onready var dirt_world_2d: DirtWorld2D = %DirtWorld2D

func _process(delta: float) -> void:
	dirt_world_2d.vacuum_position = ((Vector2(player_position.x, player_position.z) / size) + Vector2(0.5, 0.5)) * Vector2(dirt_world_2d.size.x, dirt_world_2d.size.y)

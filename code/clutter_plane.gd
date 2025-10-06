class_name ClutterPane extends CollisionShape3D

@onready var box := self.shape as BoxShape3D

@export var item_count := 2000
@export var pattern: Image
@export var min_size: float
@export var max_size: float
@export var points := 1

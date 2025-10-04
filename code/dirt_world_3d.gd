@tool
class_name DirtWorld3D extends Node3D

const DEFAULT_COLOR := Color(0.1, 0.1, 0.1)
const FLAT_TRANSFORM := Basis(Vector3.RIGHT, PI * 0.5)
const REST_Y := 0.01
const MAX_TRIES := 100

@onready var bounds: Area3D = %Bounds
@onready var bounds_shape := %BoundsShape as CollisionShape3D
@onready var bounds_shape_shape := %BoundsShape.shape as BoxShape3D
@onready var particles: MultiMeshInstance3D = %Particles
@onready var sprite3d_pattern: Sprite3D = %Pattern

var frame_share := 4
var frame_i := 0

@export var max_particles := 2000

@export var player: Node3D
@export var vacuum_radius := 0.4
@export var vacuum_power := 4.0

@export var dirt_min_size := 3.0
@export var dirt_max_size := 7.0

@export var pattern: Texture2D:
	set(p):
		pattern = p
		if is_node_ready():
			initialize_pattern()

var cell_size := Vector3.ONE * 10.0
var true_cell_size: Vector3
var true_cell_count: Vector3i
var lookup: Dictionary[int, PackedInt32Array] = {}
var alive_count := 0

signal on_dust_initialized(total: int)
signal on_dust_collected(collected: int, total: int)


func initialize_pattern():
	sprite3d_pattern.texture = pattern
	var world_size := bounds_shape_shape.size
	var world_size_xz := Vector2(world_size.x, world_size.z)
	var size_scale := world_size_xz / Vector2(pattern.get_image().get_size())
	sprite3d_pattern.pixel_size = minf(size_scale.x, size_scale.y)


func _ready() -> void:
	initialize_pattern()
	particles.multimesh.instance_count = max_particles
	var world_size := bounds_shape_shape.size
	var world_size_xz := Vector2(world_size.x, world_size.z)
	true_cell_size = Vector3(ceil(world_size.x / cell_size.x), ceil(world_size.y / cell_size.y), ceil(world_size.z / cell_size.z))
	
	var pattern_image := pattern.get_image()
	var pattern_size := pattern_image.get_size()
	
	if pattern_image.is_compressed():
		pattern_image.decompress()
	
	for i in range(max_particles):
		var pos2d: Vector2 = Vector2.ZERO
		var sample_color := Color.BLACK
		var pos_chosen := false
		var tries := 0
		while not pos_chosen and tries < MAX_TRIES:
			var param2d := Vector2(randf(), randf())
			pos2d = (param2d - 0.5 * Vector2.ONE) * world_size_xz
			var pattern_coord := Vector2i(floori(param2d.x * pattern_size.x), floori(param2d.y * pattern_size.y))
			var sample := pattern_image.get_pixelv(pattern_coord)
			if randf() < sample.a:
				pos_chosen = true
				sample_color = sample
				break
			else:
				tries += 1
		
		if tries >= MAX_TRIES:
			continue
		
		var size := dirt_min_size + randf() * (dirt_max_size - dirt_min_size)
		var part_basis := FLAT_TRANSFORM.scaled(Vector3.ONE * size).rotated(Vector3.UP, randf() * TAU)
		var part_position := Vector3(pos2d.x, 0, pos2d.y) + bounds_shape.position + Vector3.UP * (0.01 + -0.5 * world_size.y)
		particles.multimesh.set_instance_transform(i, Transform3D(part_basis, part_position))
		particles.multimesh.set_instance_color(i, sample_color)
		alive_count += 1
	
	if on_dust_initialized:
		on_dust_initialized.emit(alive_count)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	frame_i += 1
	delta *= frame_share
	
	var batch_size := ceili(float(max_particles) / float(frame_share))
	var begin := batch_size * (frame_i % frame_share)
	
	for i in range(begin, minf(max_particles, begin + batch_size)):
		var xform := particles.multimesh.get_instance_transform(i)
		
		var ppos := xform.origin
		var pscale := xform.basis.get_scale()
		if pscale.is_zero_approx():
			continue
		
		var diff := player.position - ppos
		var dist := diff.length()
		if dist < 0.2:
			particles.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), ppos))
			alive_count -= 1
			if on_dust_collected:
				on_dust_collected.emit(max_particles - alive_count, max_particles)
			continue
		
		if dist < 0.6:
			pscale.lerp(Vector3.ONE * dirt_min_size, (0.6 - dist) / 0.6)
		
		var dir := Vector3(diff.x, 0, diff.z).normalized()
		var pull := sqrt(maxf(0.0, 1.0 - dist / vacuum_radius)) * vacuum_power
		ppos += dir * pull * delta
		ppos.y = move_toward(ppos.y, get_bottom_y(), delta)
		particles.multimesh.set_instance_transform(i, Transform3D(FLAT_TRANSFORM.scaled(pscale), ppos))
		


func get_bottom_y() -> float:
	return bounds_shape.position.y - bounds_shape_shape.size.y * 0.5 + REST_Y

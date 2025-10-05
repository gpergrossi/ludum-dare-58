@tool
class_name DirtWorld3D extends Node3D

const DEFAULT_COLOR := Color(0.5, 0.5, 0.46)
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

@export var player: RoboVac

@export var dirt_min_size := 3.0
@export var dirt_max_size := 7.0

@export var pattern: Texture2D:
	set(p):
		pattern = p
		if is_node_ready():
			initialize_pattern()

var placing_dust := false
var dust_ready := false
var dust_placed := 0

var pattern_image: Image = null
var alive_count := 0
var dust_collected := 0
var max_dust_collected := 0

signal on_dust_ready(world: DirtWorld3D)
signal on_dust_placement_progress(world: DirtWorld3D, value: int, max: int)
signal on_dust_collected(world: DirtWorld3D, just_collected: int)


func initialize_pattern():
	sprite3d_pattern.texture = pattern
	var world_size := bounds_shape_shape.size
	var world_size_xz := Vector2(world_size.x, world_size.z)
	if pattern != null:
		var size_scale := world_size_xz / Vector2(pattern.get_image().get_size())
		sprite3d_pattern.pixel_size = minf(size_scale.x, size_scale.y)


func _ready() -> void:
	if not Engine.is_editor_hint(): 
		sprite3d_pattern.visible = false
	reset()


func reset():
	alive_count = 0
	dust_collected = 0
	max_dust_collected = 0
	initialize_pattern()
	particles.multimesh.instance_count = max_particles
	particles.multimesh.visible_instance_count = 0
	placing_dust = true
	dust_ready = false
	dust_placed = 0
	if pattern != null:
		pattern_image = pattern.get_image()
		if pattern_image.is_compressed():
			pattern_image.decompress()


func do_ready():
	dust_ready = true
	placing_dust = false
	dust_collected = 0
	max_dust_collected = alive_count
	if not Engine.is_editor_hint():
		on_dust_ready.emit(self)
		player.on_dust_ready(self)
		on_dust_collected.emit(self, 0)


func _process(delta: float) -> void:
	if placing_dust:
		for i in range(100):
			if not placing_dust: break
			place_dust()
		particles.multimesh.visible_instance_count = dust_placed
		if not Engine.is_editor_hint():
			on_dust_placement_progress.emit(self, dust_placed, max_particles)
		return
	
	if dust_ready and not Engine.is_editor_hint():
		do_dust_collection(delta)


func place_dust():
	if dust_placed >= max_particles:
		do_ready()
		return
	
	var minX := (bounds_shape.position.x - bounds_shape_shape.size.x * 0.5)
	var maxX := (bounds_shape.position.x + bounds_shape_shape.size.x * 0.5)
	var minY := (bounds_shape.position.y - bounds_shape_shape.size.y * 0.5) + REST_Y
	#var maxY := (bounds_shape.position.y + bounds_shape_shape.size.y * 0.5) - REST_Y
	var minZ := (bounds_shape.position.z - bounds_shape_shape.size.z * 0.5)
	var maxZ := (bounds_shape.position.z + bounds_shape_shape.size.z * 0.5)
	
	var pos2d: Vector2 = Vector2.ZERO
	var size: float = dirt_min_size
	var sample_color := DEFAULT_COLOR
	var pos_chosen := false
	var tries := 0
	while not pos_chosen and tries < MAX_TRIES:
		var param2d := Vector2(randf(), randf())
		
		# Select a position that doesn't overlap the edge
		size = dirt_min_size + randf() * (dirt_max_size - dirt_min_size)
		var radius := 0.05 * size
		pos2d = param2d * Vector2(maxX - minX - 2 * radius, maxZ - minZ - 2 * radius) + Vector2(minX + radius, minZ + radius)
		
		if pattern_image != null:
			var pattern_size := pattern_image.get_size()
			var pattern_coord := Vector2i(floori(param2d.x * pattern_size.x), floori(param2d.y * pattern_size.y))
			var sample := pattern_image.get_pixelv(pattern_coord)
			if randf() < sample.a:
				pos_chosen = true
				sample_color = sample
				break
			else:
				tries += 1
		else:
			pos_chosen = true
			break
	
	if tries >= MAX_TRIES:
		size = dirt_min_size
	
	var part_basis := FLAT_TRANSFORM.scaled(Vector3.ONE * size).rotated(Vector3.UP, randf() * TAU)
	var part_position := Vector3(pos2d.x, minY, pos2d.y)
	var index := dust_placed
	particles.multimesh.set_instance_transform(index, Transform3D(part_basis, part_position))
	particles.multimesh.set_instance_color(index, sample_color)
	dust_placed += 1
	alive_count += 1


func do_dust_collection(delta: float):
	if not player.can_vacuum(): return
	
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
			dust_collected += 1
			on_dust_collected.emit(self, 1)
			player.on_dust_collected(self, 1)
			continue
		
		if dist < 0.6:
			pscale.lerp(Vector3.ONE * dirt_min_size, (0.6 - dist) / 0.6)
		
		var dir := Vector3(diff.x, 0, diff.z).normalized()
		var pull := sqrt(maxf(0.0, 1.0 - dist / player.vacuum_radius)) * player.get_current_vacuum_power()
		ppos += dir * pull * delta
		ppos.y = move_toward(ppos.y, get_bottom_y(), delta)
		particles.multimesh.set_instance_transform(i, Transform3D(FLAT_TRANSFORM.scaled(pscale), ppos))


func get_bottom_y() -> float:
	return bounds_shape.position.y - bounds_shape_shape.size.y * 0.5 + REST_Y

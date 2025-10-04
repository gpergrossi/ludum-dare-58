class_name DirtWorld2D extends Node2D

const DEFAULT_TRANSFORM := Transform2D(0.0, Vector2(1.0, 1.0), 0.0, Vector2(0.0, 0.0))
const frame_share := 10
var frame_i := 0

@export var vacuum_position := Vector2(400, 300)
@export var vacuum_radius := 10.0
@export var vacuum_swirl := 0.0

@export var size := Vector2i(800, 600)
@export var max_particles := 100000

var timer := 0.0
var instance_count := 0

@onready var particles: MultiMeshInstance2D = $Particles


func _ready() -> void:
	particles.multimesh.instance_count = max_particles
	
	for i in range(max_particles):
		var splat_pos := Vector2(randf() * size.x, randf() * size.y)
		var index := instance_count % max_particles
		instance_count += 1
		var pt_size := randf() * 5.0 + 2.0
		particles.multimesh.set_instance_transform_2d(index, Transform2D(0.0, Vector2(pt_size, pt_size), 0.0, splat_pos + Vector2(randf() - 0.5, randf() - 0.5).normalized() * 7.0 * randf()))
		particles.multimesh.set_instance_color(index, Color.GRAY)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	frame_i += 1
	
	timer -= delta
	if timer <= 0.0:
		for i in range(20):
			var splat_pos := Vector2(randf() * size.x, randf() * size.y)
			var index := instance_count % max_particles
			instance_count += 1
			var pt_size := randf() * 5.0 + 2.0
			particles.multimesh.set_instance_transform_2d(index, Transform2D(0.0, Vector2(pt_size, pt_size), 0.0, splat_pos + Vector2(randf() - 0.5, randf() - 0.5).normalized() * 7.0 * randf()))
			particles.multimesh.set_instance_color(index, Color.GRAY)
		timer = 0.1
	
	for i in range(frame_i % frame_share, max_particles, frame_share):
		var xform := particles.multimesh.get_instance_transform_2d(i)
		var dead := false
		if not xform.origin.is_zero_approx():
			var pt_size := xform.get_scale().x
			var diff := (vacuum_position - xform.origin)
			var dist := diff.length()
			if dist > vacuum_radius + 1.0:
				continue
			if dist < 4.0:
				dead = true
			dist = maxf(1.0, dist)
			var dir := diff.normalized()
			var pull := 30.0 * maxf(0.0, 1.0 - (dist / vacuum_radius)) / pt_size
			dir = dir.rotated(deg_to_rad(vacuum_swirl))
			xform.origin += dir * pull
			
		if dead:
			particles.multimesh.set_instance_transform_2d(i, DEFAULT_TRANSFORM)
		else:
			particles.multimesh.set_instance_transform_2d(i, xform)

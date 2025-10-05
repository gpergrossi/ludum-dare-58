class_name RoboVac extends CharacterBody3D

@export var vacuum_radius := 0.4
@export var vacuum_power := 4.0

@export var move_speed := 0.3
@export var jump_speed := 2.5
@export var turn_speed := 1.0
@export var dash_speed := 3.0
@export var dash_duration := 0.5

# Constants
const DECELLERATION := 5.0
const GRAVITY := 4.0

# Runtime use
var ground_velocity := Vector2.ZERO
var vertical_velocity := 0.0
var dash_timer := 0.0
var dash_t := 0.0


func exp_decay(a: float, b: float, decay: float, dt: float) -> float:
	return b + (a - b) * exp(-decay * dt)


func _physics_process(delta: float) -> void:
	dash_timer = move_toward(maxf(0.0, dash_timer), 0.0, delta)
	dash_t = sqrt(minf(1.0, dash_timer / dash_duration))
	
	ground_velocity = Vector2(velocity.x, velocity.z)
	vertical_velocity = velocity.y
	
	# Handle turning.
	var input_turn := Input.get_axis("turn_left", "turn_right")
	var turn := -input_turn * turn_speed * delta * (1.0 - dash_t)
	basis = basis.rotated(Vector3.UP, turn)
	velocity = velocity.rotated(Vector3.UP, turn)
	
	# Handle walking.
	var forward := -basis.z
	var forward2d := Vector2(forward.x, forward.z)
	var input_move := Input.get_axis("backward", "forward")
	var walk_velocity := forward2d * input_move * move_speed
	
	# Add the gravity.
	if not is_on_floor():
		vertical_velocity -= GRAVITY * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		print("Jump")
		vertical_velocity = jump_speed
	
	# Handle dash.
	if dash_timer <= 0.0:
		if Input.is_action_just_pressed("dash") and input_move > 0.5 and is_on_floor():
			print("Dash")
			dash_timer = dash_duration
			dash_t = 1.0
	if dash_timer > 0.0:
		var target_dash := dash_speed * dash_t
		var curr_dash := maxf(target_dash, ground_velocity.dot(forward2d))
		ground_velocity = ground_velocity + forward2d * (curr_dash - ground_velocity.dot(forward2d))
	
	# Do friction
	if is_on_floor():
		ground_velocity *= exp_decay(1.0, 0.0, 3.0, delta)
	
	# Combine velocities
	var ground_speed := ground_velocity.length()
	var current_speed_limit := maxf(move_speed, ground_speed)
	ground_velocity = ground_velocity + walk_velocity
	var new_ground_speed := ground_velocity.length()
	if new_ground_speed > current_speed_limit:
		ground_velocity = ground_velocity.normalized() * current_speed_limit
		ground_speed = current_speed_limit
	velocity = Vector3(ground_velocity.x, vertical_velocity, ground_velocity.y)
	
	# Do physics.
	move_and_slide()


func get_current_vacuum_radius() -> float:
	return vacuum_radius


func get_current_vacuum_power() -> float:
	return vacuum_power * (1.0 + dash_t)

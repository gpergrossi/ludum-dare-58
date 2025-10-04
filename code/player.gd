extends CharacterBody3D

const SPEED := 1.0
const DECELLERATION := 5.0
const JUMP_VELOCITY := 2.5
const TURN_SPEED := 1.0
const GRAVITY := 4.0


func _physics_process(delta: float) -> void:
	var vertical_velocity := velocity.y
	
	# Add the gravity.
	if not is_on_floor():
		vertical_velocity -= GRAVITY * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		print("Jump")
		vertical_velocity = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var move_speed := Input.get_axis("forward", "backward")
	if not is_zero_approx(move_speed):
		velocity = basis.z * SPEED * move_speed
	else:
		velocity = velocity.move_toward(Vector3.ZERO, DECELLERATION)

	var turn_speed := Input.get_axis("turn_left", "turn_right")
	var turn := -turn_speed * TURN_SPEED * delta
	basis = basis.rotated(Vector3.UP, turn)
	velocity = velocity.rotated(Vector3.UP, turn)
	velocity.y = vertical_velocity
	
	move_and_slide()
	

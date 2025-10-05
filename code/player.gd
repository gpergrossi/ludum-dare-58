class_name RoboVac extends CharacterBody3D

# Base Stats (Unmodified during game)
@export var base_stats := PlayerBaseStats.new()

# Current Stats (Modified during game)
var vacuum_radius := 0.4
var vacuum_power := 4.0
var move_speed := 0.5
var jump_speed := 2.5
var turn_speed := 1.0
var dash_speed := 3.0
var dash_duration := 0.5
var max_charge := 30.0
var max_dust := 1000.0
var dock_charge_rate := 10.0
var dock_dust_rate := 100.0
var move_cost_rate := 1.0     # Charge per second at max input
var dash_cost := 5.0          # One time cost
var jump_cost := 10.0         # One time cost
var fly_cost_rate := 2.0      # Charge per second at max input (in addition to move cost)
var energy_efficiency := 1.0
var energy_regen := 0.0

var upgrades := PlayerUpgrades.new()

# Constants
const DECELLERATION := 5.0
const GRAVITY := 4.0
 
# Runtime use
var respawn_transform: Transform3D
var ground_velocity := Vector2.ZERO
var vertical_velocity := 0.0
var dash_t := 0.0
var dirt_worlds: Array[DirtWorld3D] = []

# Runtime respawn might reset
var dead := false
var sleeping := false
var dash_timer := 0.0
var current_charge := 0.0
var current_dust := 0.0
var stored_dust := 0.0
var just_spawned := false
var current_dock: Dock = null

signal charge_changed(current: float, max: float)
signal dust_changed(current: float, capacity: float)
signal dust_storage_changed(amount: float)
signal battery_died(player: RoboVac)
signal respawned(player: RoboVac)
signal enter_dock(player: RoboVac, dock: Dock)
signal exit_dock(player: RoboVac, dock: Dock)
signal upgrades_changed(player: RoboVac)
signal stats_changed(player: RoboVac)
signal sleep_changed(player: RoboVac, sleeping: bool)


func _ready() -> void:
	upgrades.upgrades_changed.connect(do_upgrades_changed)
	respawn_transform = transform
	dirt_worlds.clear()
	current_dust = 0.0
	current_charge = max_charge
	respawn(false, true)


func exp_decay(a: float, b: float, decay: float, dt: float) -> float:
	return b + (a - b) * exp(-decay * dt)


func go_to_sleep() -> void:
	sleeping = true
	sleep_changed.emit(self, true)


func wake_up() -> void:
	sleeping = false
	respawn(false, false)
	sleep_changed.emit(self, false)


func respawn(lose_half_dust := false, reset_storage := false) -> void:
	current_dock = null
	transform = Transform3D(respawn_transform.basis, respawn_transform.origin + Vector3.UP * 0.1)
	dead = false
	dash_timer = 0.0
	current_charge = max_charge
	charge_changed.emit(current_charge, max_charge)
	just_spawned = true # Block UI when just spawned
	if lose_half_dust:
		LevelManager.lost_dust += current_dust * 0.5
		current_dust *= 0.5
		dust_changed.emit(current_dust, max_dust)
		just_spawned = false # Show UI when you die and respawn
	if reset_storage:
		stored_dust = 0
		current_dust = 0
	respawned.emit(self)


func reset_stats() -> void:
	vacuum_radius = base_stats.vacuum_radius
	vacuum_power = base_stats.vacuum_power
	move_speed = base_stats.move_speed
	jump_speed = base_stats.jump_speed
	turn_speed = base_stats.turn_speed
	dash_speed = base_stats.dash_speed
	dash_duration = base_stats.dash_duration
	max_charge = base_stats.max_charge
	max_dust = base_stats.max_dust
	dock_charge_rate = base_stats.dock_charge_rate
	dock_dust_rate = base_stats.dock_dust_rate
	move_cost_rate = base_stats.move_cost_rate
	dash_cost = base_stats.dash_cost
	jump_cost = base_stats.jump_cost
	fly_cost_rate = base_stats.fly_cost_rate
	energy_efficiency = base_stats.energy_efficiency
	energy_regen = base_stats.energy_regen
	stats_changed.emit()


func update_stats() -> void:
	reset_stats()
	upgrades.apply_all_purchased(self)
	stats_changed.emit()


func do_upgrades_changed() -> void:
	upgrades_changed.emit()
	update_stats()


func _physics_process(delta: float) -> void:
	current_charge += delta * energy_regen
	
	if current_charge <= 0.0 and not dead and energy_regen == 0.0:
		dead = true
		battery_died.emit(self)
	
	var old_charge := current_charge
	dash_timer = move_toward(maxf(0.0, dash_timer), 0.0, delta)
	dash_t = sqrt(minf(1.0, dash_timer / dash_duration))
	
	ground_velocity = Vector2(velocity.x, velocity.z)
	vertical_velocity = velocity.y
	
	# Handle dock.
	if current_dock != null:
		current_charge = move_toward(current_charge, max_charge, delta * dock_charge_rate)
		var dust_collected := minf(current_dust, delta * dock_dust_rate)
		stored_dust += dust_collected
		current_dust -= dust_collected
		dust_changed.emit(current_dust, max_dust)
		dust_storage_changed.emit(stored_dust)
	
	var input_move := 0.0
	var forward := -basis.z
	var forward2d := Vector2(forward.x, forward.z)
	var walk_velocity := Vector2.ZERO
	if not sleeping:
		# Handle turning.
		if current_charge > 0.0:
			var input_turn := Input.get_axis("turn_left", "turn_right")
			var turn := -input_turn * turn_speed * delta * (1.0 - dash_t)
			basis = basis.rotated(Vector3.UP, turn)
			velocity = velocity.rotated(Vector3.UP, turn)
		
		# New basis from turn
		forward = -basis.z
		forward2d = Vector2(forward.x, forward.z)
	
		# Handle moving.
		input_move = Input.get_axis("backward", "forward")
		var max_input_move := minf(1.0, current_charge / ((move_cost_rate / energy_efficiency) * delta))
		input_move = signf(input_move) * minf(max_input_move, absf(input_move))
		walk_velocity = forward2d * input_move * move_speed
		
		# Handle move charge drain
		current_charge -= absf(input_move) * (move_cost_rate / energy_efficiency) * delta
	
	# Add the gravity.
	if not is_on_floor():
		vertical_velocity -= GRAVITY * delta
	
	if not sleeping:
		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor() and current_charge > (jump_cost / energy_efficiency):
			print("Jump")
			current_charge -= (jump_cost / energy_efficiency)
			vertical_velocity = jump_speed
	
		# Handle dash.
		if dash_timer <= 0.0:
			if Input.is_action_just_pressed("dash") and input_move > 0.5 and is_on_floor() and current_charge > (dash_cost / energy_efficiency):
				print("Dash")
				current_charge -= (dash_cost / energy_efficiency)
				dash_timer = dash_duration
				dash_t = 1.0
		if dash_timer > 0.0:
			var target_dash := dash_speed * dash_t
			var curr_dash := maxf(target_dash, ground_velocity.dot(forward2d))
			ground_velocity = ground_velocity + forward2d * (curr_dash - ground_velocity.dot(forward2d))
	
	# Do friction
	if is_on_floor():
		ground_velocity *= exp_decay(1.0, 0.0, 3.0, delta)
		if ground_velocity.length() < move_speed:
			ground_velocity *= exp_decay(1.0, 0.0, 6.0, delta)
	
	# Combine velocities
	var ground_speed := ground_velocity.length()
	var current_speed_limit := maxf(move_speed, ground_speed)
	ground_velocity = ground_velocity + walk_velocity
	var new_ground_speed := ground_velocity.length()
	if new_ground_speed > current_speed_limit:
		ground_velocity = ground_velocity.normalized() * current_speed_limit
		ground_speed = current_speed_limit
	velocity = Vector3(ground_velocity.x, vertical_velocity, ground_velocity.y)
	
	if not is_equal_approx(current_charge, old_charge):
		charge_changed.emit(current_charge, max_charge)
	
	# Do physics.
	move_and_slide()


func can_open_dock() -> bool:
	if just_spawned:
		just_spawned = false
		return false
	return true


func can_vacuum() -> bool:
	return current_dust < max_dust


func get_current_vacuum_radius() -> float:
	return vacuum_radius


func get_current_vacuum_power() -> float:
	return vacuum_power * (1.0 + dash_t)


func on_dust_ready(world: DirtWorld3D) -> void:
	dirt_worlds.append(world)
	print("Loaded dirt surface (" + str(len(dirt_worlds)) + " total)")


func on_dust_collected(world: DirtWorld3D, just_added: int) -> void:
	if not dirt_worlds.has(world):
		dirt_worlds.append(world)
	
	current_dust += just_added
	if dust_changed:
		# Note: you are allowed to pick up more dust, but at this point the vacuum should turn off
		# We will HIDE the fact that you are holding more than max from the player.
		dust_changed.emit(minf(current_dust, max_dust), max_dust)


func notify_enter_dock(dock: Dock):
	current_dock = dock
	enter_dock.emit(self, dock)


func notify_exit_dock(dock: Dock):
	current_dock = null
	exit_dock.emit(self, dock)

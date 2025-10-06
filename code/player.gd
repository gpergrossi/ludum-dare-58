class_name RoboVac extends CharacterBody3D

@onready var art: Node3D = %Art
@onready var cat_hat: MeshInstance3D = %Cat_Hat
@onready var coppter_hat_v_1: Node3D = %CoppterHat_v1
@onready var main_camera: Camera3D = %"Main Camera"
@onready var ring_particles: CPUParticles3D = %RingParticles
@onready var collider_main_body: CollisionShape3D = %ColliderMainBody

const DIALOG_COOLDOWN_MAX := 10.0


# Base Stats (Unmodified during game)
var base_stats := PlayerBaseStats.new()

@export var animations: AnimationPlayer

# Current Stats (Modified during game)
var vacuum_radius: float
var vacuum_power: float
var move_speed: float
var jump_speed: float
var turn_speed: float
var dash_speed: float
var dash_duration: float
var max_charge: float
var max_dust: float
var move_cost_rate: float     # Charge per second at max input
var dash_cost: float          # One time cost
var jump_cost: float          # One time cost
var fly_cost_rate: float      # Charge per second at max input (in addition to move cost)
var energy_efficiency: float
var energy_regen: float
var max_air_jumps: int

var upgrades := PlayerUpgrades.new()

# Constants
const DECELLERATION := 5.0
const GRAVITY := 4.0
 
# Runtime use
var respawn_transform: Transform3D
var ground_velocity := Vector2.ZERO
var vertical_velocity := 0.0
var dash_t := 0.0
var sample_angle := 0.0
var last_hit := Time.get_ticks_msec()
var last_position := Vector3.ZERO
var not_moving_time := 0.0
var frustration_time_plus := 0.0
var frustration_time_minus := 0.0

# Runtime respawn might reset
var dead := false
var sleeping := false
var dash_timer := 0.0
var current_charge := 0.0
var current_dust := 0.0
var stored_dust := 0.0
var just_spawned := false
var current_dock: Dock = null
var air_jumps_used := 0
var dialog_cooldown := 0.0
var is_flying := false

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
signal pickup_static(player: RoboVac, coll: StaticBodyGamePiece)
signal pickup_special(player: RoboVac, coll: StaticBodyGamePiece)
signal player_is_stuck(player: RoboVac)
signal player_is_out_of_bounds(player: RoboVac)
signal player_home_dialog(player: RoboVac)


func _ready() -> void:
	reset_stats()
	upgrades.upgrades_changed.connect(do_upgrades_changed)
	respawn_transform = transform
	current_dust = 0.0
	current_charge = max_charge
	respawn(0.0, false, true)


func exp_decay(a: float, b: float, decay: float, dt: float) -> float:
	return b + (a - b) * exp(-decay * dt)


func go_to_sleep() -> void:
	sleeping = true
	sleep_changed.emit(self, true)


func wake_up() -> void:
	sleeping = false
	respawn(0.0, true, false)
	sleep_changed.emit(self, false)


func respawn(penalty := 0.0, suppress_shop := true, reset_storage := false) -> void:
	current_dock = null
	air_jumps_used = 0
	dialog_cooldown = 0.0
	is_flying = false
	transform = Transform3D(respawn_transform.basis, respawn_transform.origin + Vector3.UP * 0.1)
	dead = false
	dash_timer = 0.0
	current_charge = max_charge
	charge_changed.emit(current_charge, max_charge)
	just_spawned = suppress_shop # Block UI when just spawned
	if penalty > 0.0:
		var penalty_dust := clampi(floori(penalty * current_dust), 0, current_dust)
		LevelManager.lost_dust += penalty_dust
		current_dust -= penalty_dust
		dust_changed.emit(current_dust, max_dust)
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
	move_cost_rate = base_stats.move_cost_rate
	dash_cost = base_stats.dash_cost
	jump_cost = base_stats.jump_cost
	fly_cost_rate = base_stats.fly_cost_rate
	energy_efficiency = base_stats.energy_efficiency
	energy_regen = base_stats.energy_regen
	max_air_jumps = base_stats.max_air_jumps
	stats_changed.emit()


func update_stats() -> void:
	reset_stats()
	upgrades.apply_all_purchased(self)
	stats_changed.emit()


func do_upgrades_changed() -> void:
	upgrades_changed.emit()
	update_stats()


func _physics_process(delta: float) -> void:
	#var time := Time.get_ticks_msec()
	#
	#var up := global_basis.y
	#var new_up := global_basis.y
	#
	#sample_angle += deg_to_rad(120)
	#var sample_offset := global_basis.x.rotated(global_basis.y, sample_angle) * 0.15
	#var query_a := PhysicsRayQueryParameters3D.create(global_position + sample_offset + up * 0.1, global_position + sample_offset - up * 0.25, ~4)
	#var query_b := PhysicsRayQueryParameters3D.create(global_position - sample_offset + up * 0.1, global_position - sample_offset - up * 0.25, ~4)
	#query_a.collide_with_areas = false
	#query_a.collide_with_bodies = true
	#query_a.hit_back_faces = false
	#query_a.hit_from_inside = false
	#query_b.collide_with_areas = false
	#query_b.collide_with_bodies = true
	#query_b.hit_back_faces = false
	#query_b.hit_from_inside = false
	#
	#var space_state := get_world_3d().direct_space_state
	#var result_a := space_state.intersect_ray(query_a)
	#var result_b := space_state.intersect_ray(query_b)
	#
	#if result_a and result_b:
		#var pos_a: Vector3 = result_a.position
		#var pos_b: Vector3 = result_b.position
		#var ray := (pos_a - pos_b).normalized()
		#var perp_axis := sample_offset.rotated(global_basis.y, 0.5 * PI)
		#new_up = ray.cross(perp_axis)
		#if new_up.is_zero_approx():  new_up = Vector3.UP
		#else:  new_up = new_up.normalized()
		#last_hit = time
	#
	#art.basis = Basis()
	#if (time - last_hit) > 500:
		#new_up = Vector3.UP
	#if new_up.dot(Vector3.UP) > cos(deg_to_rad(50)):
		#var tip_axis := up.cross(new_up)
		#if not tip_axis.is_zero_approx():
			#tip_axis = tip_axis.normalized()
			#var tip_angle := up.signed_angle_to(new_up, tip_axis)
			#art.global_basis = art.global_basis.rotated(tip_axis, tip_angle * 0.05)
	
	if Input.is_action_just_pressed("home") and upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Teleport):
		player_home_dialog.emit(self)
	
	if upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Helicopter):
		coppter_hat_v_1.visible = true
		cat_hat.visible = false
	else:
		coppter_hat_v_1.visible = false
	
	var collider_body := collider_main_body as CollisionShape3D
	var collider_cylinder := collider_main_body.shape as CylinderShape3D
	if upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Low_Rider):
		collider_body.position.y = 0.069
		collider_cylinder.height = 0.059
	else:
		collider_body.position.y = 0.103
		collider_cylinder.height = 0.127
	
	var estimate_velocity := (position - last_position).length() / delta
	last_position = position
	if estimate_velocity < 0.1:
		not_moving_time += delta
	else:
		not_moving_time = 0.0
		frustration_time_plus = 0.0
		frustration_time_minus = 0.0
	
	dialog_cooldown = move_toward(dialog_cooldown, 0.0, delta)
	
	var query := PhysicsRayQueryParameters3D.create(main_camera.global_position, global_position)
	query.hit_from_inside = true
	query.hit_back_faces = true
	var space_state := get_world_3d().direct_space_state
	var result := space_state.intersect_ray(query)
	if result:
		if result.collider is CameraHide:
			var ch := result.collider as CameraHide
			ch.do_hide()
	
	var old_charge := current_charge
	
	current_charge = move_toward(current_charge, max_charge, delta * energy_regen)
	
	if current_charge <= 0.0 and not dead and energy_regen == 0.0:
		dead = true
		battery_died.emit(self)
	
	dash_timer = move_toward(maxf(0.0, dash_timer), 0.0, delta)
	dash_t = sqrt(minf(1.0, dash_timer / dash_duration))
	
	ground_velocity = Vector2(velocity.x, velocity.z)
	vertical_velocity = velocity.y
	
	# Handle dock.
	if current_dock != null:
		current_charge = move_toward(current_charge, max_charge, delta * max_charge * 0.25)
		var dust_collected := minf(current_dust, delta * max_dust * 0.25)
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
		
		if absf(input_move) > 0.5 and not_moving_time > 0.5:
			if input_move > 0.5:
				frustration_time_plus += delta
			else:
				frustration_time_minus += delta
			if frustration_time_plus > 1.0 and frustration_time_minus > 1.0 and dialog_cooldown <= 0.0:
				player_is_stuck.emit(self)
				dialog_cooldown = DIALOG_COOLDOWN_MAX
		
		# Handle move charge drain
		current_charge -= absf(input_move) * (move_cost_rate / energy_efficiency) * delta
	
	# Add the gravity.
	if not is_on_floor():
		# Handle flying
		var ascent_speed := 0.0
		var ascent_accel := 1.0
		
		if upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Helicopter):
			ascent_speed = 0.1
			ascent_accel = 1.0
		
		if upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Jetpack):
			ascent_speed = 1.0
			ascent_accel = 4.0
		
		if ascent_speed > 0.0 and Input.is_action_pressed("jump") and vertical_velocity < ascent_speed:
			var fly := minf(1.0, current_charge / ((fly_cost_rate / energy_efficiency) * delta))
			vertical_velocity = move_toward(vertical_velocity, ascent_speed, ascent_accel * fly * delta)
			current_charge -= fly * (fly_cost_rate / energy_efficiency) * delta
			is_flying = true
		else:
			# Regular gravity
			vertical_velocity -= GRAVITY * delta
			is_flying = false
	else:
			is_flying = false
	
	ring_particles.emitting = is_flying
	
	if not sleeping:
		# Handle jump.
		if is_on_floor():
			air_jumps_used = 0
		
		if upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Jump):
			if Input.is_action_just_pressed("jump") and current_charge > (jump_cost / energy_efficiency):
				print("try jump. " + ("on ground" if is_on_floor() else (str(air_jumps_used) + "/" + str(max_air_jumps) + " used")))
				if is_on_floor() or air_jumps_used < max_air_jumps:
					current_charge -= (jump_cost / energy_efficiency)
					vertical_velocity += jump_speed
					if not is_on_floor(): 
						air_jumps_used += 1
						animations.play("Double_Jump")
					else:
						animations.play("Jump_ani")
	
		if is_on_floor():
			if not animations.is_playing():
				animations.play("Walk_ani")
	
		# Handle dash.
		if dash_timer <= 0.0:
			if upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Dash):
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
	
	# Cheats
	if Input.is_key_pressed(KEY_PAGEUP):
		stored_dust += 100000
	
	# Pick up medium and large objects
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is StaticBodyGamePiece:
			var sbgp := collider as StaticBodyGamePiece
			if sbgp.is_queued_for_deletion(): continue
			if (sbgp.size_class == 0) or \
				(sbgp.size_class == 1 and upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Stuff_Collector_I)) or \
				(sbgp.size_class == 2 and upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Stuff_Collector_II)) or \
				(sbgp.size_class == 3 and upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Stuff_Pulveriser)):
					var pay := 1
					match sbgp.size_class:
						1: pay = 15
						2: pay = 50
						3: pay = 350 
					on_dust_collected(null, pay)
					sbgp.queue_free()
					pickup_static.emit(self, sbgp)
					do_special_pickups(sbgp)
		
		if collider.name == "OutOfBounds" and dialog_cooldown <= 0.0:
			player_is_out_of_bounds.emit(self)
			dialog_cooldown = DIALOG_COOLDOWN_MAX


func can_open_dock() -> bool:
	if just_spawned:
		just_spawned = false
		return false
	return true


func can_vacuum(plane: ClutterPlane) -> bool:
	if current_dust >= max_dust: return false
	if plane.size_class >= 1 and not upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Stuff_Collector_I): return false
	if plane.size_class >= 2 and not upgrades.is_upgrade_purchased(PlayerUpgrades.Upgrade_Stuff_Collector_II): return false
	return true


func get_current_vacuum_radius() -> float:
	return vacuum_radius


func get_current_vacuum_power() -> float:
	return vacuum_power * (1.0 + dash_t)


func on_dust_collected(_plane: ClutterPlane, amount: int) -> void:
	current_dust += amount
	# Note: you are allowed to pick up more dust, but at this point the vacuum should turn off
	# We will HIDE the fact that you are holding more than max from the player.
	dust_changed.emit(minf(current_dust, max_dust), max_dust)


func notify_enter_dock(dock: Dock):
	current_dock = dock
	enter_dock.emit(self, dock)


func notify_exit_dock(dock: Dock):
	current_dock = null
	exit_dock.emit(self, dock)


func do_special_pickups(sbgp: StaticBodyGamePiece):
	print("Special pickup?")
	if sbgp.name == "CatRoll":
		pickup_special.emit(self, sbgp.name)
		cat_hat.visible = true

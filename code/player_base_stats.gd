class_name PlayerBaseStats extends Resource

@export var vacuum_radius := 0.24
@export var vacuum_power := 4.0

# BASE stats, modifiers come from player_upgrades.gd
@export var move_speed := 0.5
@export var jump_speed := 2.2
@export var turn_speed := 1.0
@export var dash_speed := 4.0
@export var dash_duration := 0.75
@export var max_charge := 30.0
@export var max_dust := 1000.0

@export var move_cost_rate := 1.0     # Charge per second at max input
@export var dash_cost := 2.0          # One time cost
@export var jump_cost := 2.0          # One time cost
@export var fly_cost_rate := 2.0      # Charge per second at max input (in addition to move cost)
@export var energy_efficiency := 1.0  # The cost of all of the above is divide by this number
@export var energy_regen := 0.0

@export var max_air_jumps: int

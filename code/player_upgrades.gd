class_name PlayerUpgrades extends RefCounted

var purchases: Dictionary[StringName, bool] = {}
var all_upgrades: Array[StringName] = []

const ICON_BATTERY = preload("uid://qpxqiuts6mjq")
const ICON_CARPET = preload("uid://bpelqn7tvp60a")
const ICON_DASH = preload("uid://deidsur08mfn4")
const ICON_DOUBLE_JUMP = preload("uid://dp5lgjsufx6g7")
const ICON_DUST_CAPACITY = preload("uid://cflon5t0qdxom")
const ICON_EFFICIENCY = preload("uid://dnuryvw88ww5a")
const ICON_ENERGY_REGEN = preload("uid://bs8f3ju6jgbvl")
const ICON_HELICOPTOR = preload("uid://bua74lteas6au")
const ICON_JUMP = preload("uid://c7nm4jhwpdn8f")
const ICON_SMALL_OBJECTS = preload("uid://cjm20b08edp56")
const ICON_SPEED = preload("uid://bubet8xaic1u0")
const ICON_TURNING = preload("uid://wu4wpydjussu")
const ICON_VACCUM_POWER = preload("uid://dvrf55pkxxmo5")

signal upgrades_changed()

func _init() -> void:
	purchases.clear()
	gen_upgrades_list()
	upgrades_changed.emit()

func grant_upgrade(name: StringName) -> void:
	if all_upgrades.has(name):
		purchases[name] = true
		upgrades_changed.emit()

func grant_all_upgrades() -> void:
	for upgrade in all_upgrades:
		purchases[upgrade] = true
	upgrades_changed.emit()

func is_upgrade_purchased(name: StringName) -> bool:
	return purchases.has(name)

func is_upgrade_unlocked(name: StringName) -> bool:
	for prereq in get_upgrade_prereqs(name):
		if not is_upgrade_purchased(prereq): return false
	return true

func apply_all_purchased(player: RoboVac) -> void:
	var all_upgrades: Array[StringName] = purchases.keys()
	var applied: Dictionary[StringName, bool] = {}
	while applied.size() < all_upgrades.size():
		for upgrade in all_upgrades:
			if applied.has(upgrade): continue
			var can_apply := true
			for prereq in get_upgrade_prereqs(upgrade):
				if not applied.has(prereq):
					can_apply = false
					break
			if can_apply:
				apply_upgrade(upgrade, player)
				applied[upgrade] = true

func sort_prereqs_first(upgrade_a: StringName, upgrade_b: StringName) -> bool:
	var next_wave: Array[StringName] = [upgrade_a]
	while not next_wave.is_empty():
		var wave := next_wave
		next_wave = []
		for upgrade in wave:
			for prereq in get_upgrade_prereqs(upgrade):
				if prereq == upgrade_b: return false
				next_wave.append(upgrade)
	return true


const Upgrade_Speed_I: StringName = "Speed I"
const Upgrade_Speed_II: StringName = "Speed II"
const Upgrade_Speed_III: StringName = "Speed III"

const Upgrade_Turning_I: StringName = "Turning I"
const Upgrade_Turning_II: StringName = "Turning II"
const Upgrade_Turning_III: StringName = "Turning III"

const Upgrade_Battery_I: StringName = "Battery I"
const Upgrade_Battery_II: StringName = "Battery II"
const Upgrade_Battery_III: StringName = "Battery III"

const Upgrade_Vacuum_Radius_I: StringName = "Vacuum Power I"
const Upgrade_Vacuum_Radius_II: StringName = "Vacuum Power II"
const Upgrade_Vacuum_Radius_III: StringName = "Vacuum Power III"

const Upgrade_Vacuum_Capacity_I: StringName = "Dust Capacity I"
const Upgrade_Vacuum_Capacity_II: StringName = "Dust Capacity II"
const Upgrade_Vacuum_Capacity_III: StringName = "Dust Capacity III"

const Upgrade_Efficiency_I: StringName = "Efficiency I"
const Upgrade_Efficiency_II: StringName = "Efficiency II"
const Upgrade_Efficiency_III: StringName = "Efficiency III"

const Upgrade_Carpet_Speed: StringName = "Move Faster on Carpets"
const Upgrade_Cat_Speed: StringName = "Move Faster when Cat"
const Upgrade_Low_Rider: StringName = "Low Rider"
const Upgrade_Stuff_Collector_I: StringName = "Vacuum Up Small Objects"
const Upgrade_Stuff_Collector_II: StringName = "Vacuum Up Medium Objects"
const Upgrade_Stuff_Pulveriser: StringName = "Pulverise Large Furniture"

const Upgrade_Dash: StringName = "Unlock Dash"
const Upgrade_Jump: StringName = "Unlock Jump"
const Upgrade_Double_Jump: StringName = "Unlock Double Jump"
const Upgrade_Helicopter: StringName = "Unlock Helicopter"
const Upgrade_Jetpack: StringName = "Unlock Jetpack"
const Upgrade_Quick_Turn: StringName = "Quick Turn"
const Upgrade_Teleport: StringName = "Teleport Home (Press H)"
const Upgrade_Generator: StringName = "Unlock Slow Energy Regen"

class UpgradeData extends RefCounted:
	var name: StringName
	var cost: float
	var required: Array[StringName]
	var apply_once: Callable
	var purchased := false
	func _init(name_: StringName, cost_: float, required_: Array[StringName], apply_once_: Callable) -> void:
		self.name = name_
		self.cost = cost_
		self.required = required_
		self.apply_once = apply_once_


func gen_upgrades_list():
	all_upgrades.append(Upgrade_Speed_I)
	all_upgrades.append(Upgrade_Speed_II)
	all_upgrades.append(Upgrade_Speed_III)

	all_upgrades.append(Upgrade_Turning_I)
	all_upgrades.append(Upgrade_Turning_II)
	all_upgrades.append(Upgrade_Turning_III)

	all_upgrades.append(Upgrade_Battery_I)
	all_upgrades.append(Upgrade_Battery_II)
	all_upgrades.append(Upgrade_Battery_III)

	all_upgrades.append(Upgrade_Vacuum_Radius_I)
	all_upgrades.append(Upgrade_Vacuum_Radius_II)
	all_upgrades.append(Upgrade_Vacuum_Radius_III)

	all_upgrades.append(Upgrade_Vacuum_Capacity_I)
	all_upgrades.append(Upgrade_Vacuum_Capacity_II)
	all_upgrades.append(Upgrade_Vacuum_Capacity_III)

	all_upgrades.append(Upgrade_Efficiency_I)
	all_upgrades.append(Upgrade_Efficiency_II)
	all_upgrades.append(Upgrade_Efficiency_III)

	all_upgrades.append(Upgrade_Low_Rider)
	all_upgrades.append(Upgrade_Stuff_Collector_I)
	all_upgrades.append(Upgrade_Stuff_Collector_II)

	all_upgrades.append(Upgrade_Dash)
	all_upgrades.append(Upgrade_Jump)
	all_upgrades.append(Upgrade_Double_Jump)
	all_upgrades.append(Upgrade_Helicopter)
	all_upgrades.append(Upgrade_Jetpack)
	all_upgrades.append(Upgrade_Teleport)
	all_upgrades.append(Upgrade_Generator)


func get_upgrade_cost(upgrade: StringName) -> int:
	match upgrade:
		Upgrade_Speed_I: return 200
		Upgrade_Speed_II: return 500
		Upgrade_Speed_III: return 1000

		Upgrade_Turning_I: return 150
		Upgrade_Turning_II: return 300
		Upgrade_Turning_III: return 600

		Upgrade_Battery_I: return 500
		Upgrade_Battery_II: return 1000
		Upgrade_Battery_III: return 2000

		Upgrade_Vacuum_Radius_I: return 750
		Upgrade_Vacuum_Radius_II: return 1500
		Upgrade_Vacuum_Radius_III: return 3000

		Upgrade_Vacuum_Capacity_I: return 1000
		Upgrade_Vacuum_Capacity_II: return 2000
		Upgrade_Vacuum_Capacity_III: return 4000

		Upgrade_Efficiency_I: return 2000
		Upgrade_Efficiency_II: return 4000
		Upgrade_Efficiency_III: return 8000

		Upgrade_Carpet_Speed: return 750
		Upgrade_Cat_Speed: return 2500
		Upgrade_Low_Rider: return 1250
		Upgrade_Stuff_Collector_I: return 300
		Upgrade_Stuff_Collector_II: return 2000

		Upgrade_Dash: return 500
		Upgrade_Jump: return 1500
		Upgrade_Helicopter: return 3000
		Upgrade_Double_Jump: return 3000
		Upgrade_Jetpack: return 6000
		Upgrade_Quick_Turn: return 750
		Upgrade_Teleport: return 2750
		Upgrade_Generator: return 8000
	
	push_warning("No such upgrade \"" + upgrade + "\"!")
	return -1


func get_upgrade_prereqs(upgrade: StringName) -> Array[StringName]:
	match upgrade:
		Upgrade_Speed_I: return []
		Upgrade_Speed_II: return [Upgrade_Speed_I]
		Upgrade_Speed_III: return [Upgrade_Speed_II]

		Upgrade_Turning_I: return []
		Upgrade_Turning_II: return [Upgrade_Turning_I]
		Upgrade_Turning_III: return [Upgrade_Turning_II]

		Upgrade_Battery_I: return []
		Upgrade_Battery_II: return [Upgrade_Battery_I]
		Upgrade_Battery_III: return [Upgrade_Battery_II]

		Upgrade_Vacuum_Radius_I: return []
		Upgrade_Vacuum_Radius_II: return [Upgrade_Vacuum_Radius_I]
		Upgrade_Vacuum_Radius_III: return [Upgrade_Vacuum_Radius_II]

		Upgrade_Vacuum_Capacity_I: return []
		Upgrade_Vacuum_Capacity_II: return [Upgrade_Vacuum_Capacity_I]
		Upgrade_Vacuum_Capacity_III: return [Upgrade_Vacuum_Capacity_II]

		Upgrade_Efficiency_I: return []
		Upgrade_Efficiency_II: return [Upgrade_Efficiency_I]
		Upgrade_Efficiency_III: return [Upgrade_Efficiency_II]

		Upgrade_Carpet_Speed: return []
		Upgrade_Cat_Speed: return []
		Upgrade_Low_Rider: return []
		
		Upgrade_Stuff_Collector_I: return []
		Upgrade_Stuff_Collector_II: return [Upgrade_Stuff_Collector_I]
		Upgrade_Stuff_Pulveriser: return [Upgrade_Stuff_Collector_II]

		Upgrade_Dash: return []
		Upgrade_Jump: return []
		Upgrade_Double_Jump: return [Upgrade_Jump]
		Upgrade_Helicopter: return [Upgrade_Double_Jump]
		Upgrade_Jetpack: return [Upgrade_Helicopter]
		
		Upgrade_Quick_Turn: return []
		
		Upgrade_Generator: return []
		Upgrade_Teleport: return []
	
	push_warning("No such upgrade \"" + upgrade + "\"!")
	return []


func apply_upgrade(upgrade : StringName, player: RoboVac) -> void:
	match upgrade:
		Upgrade_Speed_I:  player.move_speed = player.base_stats.move_speed * 1.5
		Upgrade_Speed_II:  player.move_speed = player.base_stats.move_speed * 1.75
		Upgrade_Speed_III:  player.move_speed = player.base_stats.move_speed * 2.0

		Upgrade_Turning_I:  player.turn_speed = player.base_stats.turn_speed * 1.25
		Upgrade_Turning_II:  player.turn_speed = player.base_stats.turn_speed * 1.5
		Upgrade_Turning_III:  player.turn_speed = player.base_stats.turn_speed * 1.75

		Upgrade_Battery_I:  player.max_charge = player.base_stats.max_charge * 2.0
		Upgrade_Battery_II:  player.max_charge = player.base_stats.max_charge * 4.0
		Upgrade_Battery_III:  player.max_charge = player.base_stats.max_charge * 8.0

		Upgrade_Vacuum_Radius_I:  player.vacuum_radius = player.base_stats.vacuum_radius * 1.25
		Upgrade_Vacuum_Radius_II:  player.vacuum_radius = player.base_stats.vacuum_radius * 1.5
		Upgrade_Vacuum_Radius_III:  player.vacuum_radius = player.base_stats.vacuum_radius * 2.0

		Upgrade_Vacuum_Capacity_I:  player.max_dust = player.base_stats.max_dust * 2.0
		Upgrade_Vacuum_Capacity_II:  player.max_dust = player.base_stats.max_dust * 4.0
		Upgrade_Vacuum_Capacity_III:  player.max_dust = player.base_stats.max_dust * 8.0

		Upgrade_Efficiency_I:  player.energy_efficiency = player.base_stats.energy_efficiency * 1.10
		Upgrade_Efficiency_II:  player.energy_efficiency = player.base_stats.energy_efficiency * 1.20
		Upgrade_Efficiency_III:  player.energy_efficiency = player.base_stats.energy_efficiency * 1.25

		Upgrade_Carpet_Speed: return
		Upgrade_Cat_Speed: return
		Upgrade_Low_Rider: return

		Upgrade_Stuff_Collector_I: return
		Upgrade_Stuff_Collector_II: return
		Upgrade_Stuff_Pulveriser: return

		Upgrade_Dash: return
		Upgrade_Jump: return
		Upgrade_Double_Jump:  player.max_air_jumps = 1
		Upgrade_Quick_Turn: return
		
		Upgrade_Helicopter: return
		Upgrade_Jetpack: return
		
		Upgrade_Generator: player.energy_regen = 2.0
		Upgrade_Teleport: return


func get_upgrade_icon(upgrade: StringName) -> Texture2D:
	match upgrade:
		Upgrade_Speed_I: return ICON_SPEED
		Upgrade_Speed_II: return ICON_SPEED
		Upgrade_Speed_III: return ICON_SPEED

		Upgrade_Turning_I: return ICON_TURNING
		Upgrade_Turning_II: return ICON_TURNING
		Upgrade_Turning_III: return ICON_TURNING

		Upgrade_Battery_I: return ICON_BATTERY
		Upgrade_Battery_II: return ICON_BATTERY
		Upgrade_Battery_III: return ICON_BATTERY

		Upgrade_Vacuum_Radius_I: return ICON_VACCUM_POWER
		Upgrade_Vacuum_Radius_II: return ICON_VACCUM_POWER
		Upgrade_Vacuum_Radius_III: return ICON_VACCUM_POWER

		Upgrade_Vacuum_Capacity_I: return ICON_DUST_CAPACITY
		Upgrade_Vacuum_Capacity_II: return ICON_DUST_CAPACITY
		Upgrade_Vacuum_Capacity_III: return ICON_DUST_CAPACITY

		Upgrade_Efficiency_I: return ICON_EFFICIENCY
		Upgrade_Efficiency_II: return ICON_EFFICIENCY
		Upgrade_Efficiency_III: return ICON_EFFICIENCY

		Upgrade_Carpet_Speed: return null
		Upgrade_Cat_Speed: return null
		Upgrade_Low_Rider: return ICON_CARPET
		Upgrade_Stuff_Collector_I: return ICON_SMALL_OBJECTS
		Upgrade_Stuff_Collector_II: return ICON_SMALL_OBJECTS

		Upgrade_Dash: return ICON_DASH
		Upgrade_Jump: return ICON_JUMP
		Upgrade_Helicopter: return ICON_HELICOPTOR
		Upgrade_Double_Jump: return ICON_DOUBLE_JUMP
		Upgrade_Jetpack: return ICON_HELICOPTOR
		Upgrade_Quick_Turn: return null
		Upgrade_Teleport: return null
		Upgrade_Generator: return ICON_ENERGY_REGEN
	
	push_warning("No such upgrade \"" + upgrade + "\"!")
	return null

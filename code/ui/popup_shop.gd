class_name PopupShop extends PanelContainer

const UPGRADE_UI = preload("uid://cvnlxf8mywvy4")
@onready var upgrade_list: GridContainer = %UpgradeList
@onready var label_stored_dust: Label = %LabelStoredDust
@onready var panel_container_upgr_list: PanelContainer = %PanelContainerUpgrList

@export var player: RoboVac

var upgrades: PlayerUpgrades:
	get():
		return player.upgrades

var sleeping := false
var opacity := 0.0

func _ready() -> void:
	visible = false


func _on_player_sleep_changed(_player: RoboVac, sleeping_: bool) -> void:
	self.sleeping = sleeping_
	if sleeping:
		for child in upgrade_list.get_children():
			child.visible = false
			child.name = "Garbage" + str(randi_range(0, 99999))
			child.queue_free()
		for upgrade_name in _player.upgrades.all_upgrades:
			var upgrade_ui := UPGRADE_UI.instantiate() as UpgradeUI
			upgrade_ui.shop = self
			upgrade_ui.upgrade = upgrade_name
			upgrade_ui.visible = true
			upgrade_ui.opacity = 0.0
			upgrade_list.add_child(upgrade_ui)


func _process(delta: float) -> void:
	var prev := opacity
	if sleeping:
		opacity = move_toward(opacity, 1.0, 2.0 * delta)
	else:
		opacity = 0.0
	if prev != opacity:
		self.self_modulate = Color(Color.WHITE, opacity)
		visible = (opacity != 0.0)
	upgrade_list.columns = maxi(1, floori((panel_container_upgr_list.size.x - 40) / 337))


func _on_button_next_day_pressed() -> void:
	player.wake_up()


func _on_player_dust_storage_changed(amount: float) -> void:
	label_stored_dust.text = "Stored Dust: " + str(roundi(amount * LabelDust.display_scale))

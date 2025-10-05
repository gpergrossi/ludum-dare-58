extends PanelContainer

var player: RoboVac

func _ready() -> void:
	self.visible = false

func _on_player_battery_died(player_: RoboVac) -> void:
	self.visible = true
	self.player = player_

func _on_button_pressed() -> void:
	self.player.respawn(true)

func _on_player_respawned(player_: RoboVac) -> void:
	self.visible = false
	self.player = player_

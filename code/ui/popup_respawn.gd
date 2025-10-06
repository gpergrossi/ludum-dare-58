extends PanelContainer

@onready var label_respawn_message: Label = %LabelRespawnMessage
@onready var button_yes: Button = %ButtonYes
@onready var button_no: Button = %ButtonNo

var player: RoboVac

const BATTERY_DEAD := "Battery dead.
Lose half of your dust and respawn?"

const STUCK := "Looks like you're stuck.
Respawn for free?"

const OUT_OF_BOUNDS := "Looks like you're out of bounds.
Respawn for free?"

const TELEPORT := "Teleport home for free?"

var message: String = BATTERY_DEAD:
	set(m):
		message = m
		if label_respawn_message:
			label_respawn_message.text = message

var penalty := 0.5
var can_close := false

func _ready() -> void:
	self.visible = false

func _on_player_battery_died(player_: RoboVac) -> void:
	self.visible = true
	self.player = player_
	message = BATTERY_DEAD
	penalty = 0.5
	button_yes.text = "OK"
	button_no.text = "Alright..."
	can_close = false

func _on_player_player_is_stuck(player_: RoboVac) -> void:
	self.visible = true
	self.player = player_
	message = STUCK
	penalty = 0.0
	button_yes.text = "Cool"
	button_no.text = "Yep!"
	can_close = false

func _on_player_player_is_out_of_bounds(player_: RoboVac) -> void:
	self.visible = true
	self.player = player_
	message = OUT_OF_BOUNDS
	penalty = 0.0
	button_yes.text = "OK"
	button_no.text = "In a bit."
	can_close = true

func _on_player_player_home_dialog(player_: RoboVac) -> void:
	self.visible = true
	self.player = player_
	message = TELEPORT
	penalty = 0.0
	button_yes.text = "Yes"
	button_no.text = "No"
	can_close = true

func _on_player_respawned(player_: RoboVac) -> void:
	self.visible = false
	self.player = player_
	
func _on_button_yes_pressed() -> void:
	self.visible = false
	self.player.respawn(penalty, false, false)

func _on_button_no_pressed() -> void:
	self.visible = false
	if can_close:
		pass
	else:
		self.player.respawn(penalty, false, false)

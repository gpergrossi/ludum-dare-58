extends PanelContainer

@export var current_objective := 500:
	set(target):
		current_objective = target
		if is_node_ready():
			update_progress()
			

var stored_dust := 0.0

@onready var label_goal: Label = %LabelGoal
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var label_progress: Label = %LabelProgress
@onready var button_sleep: Button = %ButtonSleep
@onready var button_highlight: ButtonHighlight = %ButtonHighlight


var player: RoboVac = null
var in_dock := false

func _ready() -> void:
	self.visible = false
	update_progress()


func update_progress():
	label_goal.text = "Deposit " + str(roundi(current_objective * LabelDust.display_scale)) + " Dust"
	progress_bar.max_value = current_objective
	progress_bar.value = stored_dust
	label_progress.text = str(roundi(stored_dust * LabelDust.display_scale)) + " / " + str(roundi(progress_bar.max_value * LabelDust.display_scale))
	button_sleep.disabled = progress_bar.value < progress_bar.max_value
	button_highlight.enabled = not button_sleep.disabled


func _on_player_enter_dock(player_: RoboVac, _dock: Dock) -> void:
	in_dock = true
	self.player = player_
	if player.can_open_dock():
		self.visible = true
	else:
		self.visible = false


func _on_player_exit_dock(_player: RoboVac, _dock: Dock) -> void:
	in_dock = false
	self.visible = false


func _on_player_dust_storage_changed(amount: float) -> void:
	stored_dust = amount
	update_progress()


func _on_button_close_pressed() -> void:
	self.visible = false


func _on_button_sleep_pressed() -> void:
	if not button_sleep.disabled:
		self.visible = false
		player.go_to_sleep()


func _unhandled_input(event: InputEvent) -> void:
	if in_dock:
		if event is InputEventKey:
			if event.is_pressed():
				if event.keycode == KEY_ESCAPE:
					self.visible = not self.visible
				if event.keycode == KEY_ENTER:
					_on_button_sleep_pressed()


func _on_level_changed(level: int) -> void:
	current_objective = LevelManager.get_objective(level)
	stored_dust = 0
	if player != null:
		player.respawn(false, true)

extends PanelContainer

@export var current_objective := 1000:
	set(target):
		current_objective = target
		if is_node_ready():
			update_progress()
			

@onready var label_goal: Label = %LabelGoal
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var label_progress: Label = %LabelProgress
@onready var button_sleep: Button = %ButtonSleep


var player: RoboVac = null


func _ready() -> void:
	self.visible = false
	progress_bar.value = 0
	update_progress()


func update_progress():
	label_goal.text = "Deposit " + str(current_objective) + " Dust"
	progress_bar.max_value = current_objective
	label_progress.text = str(roundi(progress_bar.value)) + " / " + str(roundi(progress_bar.max_value))
	button_sleep.disabled = progress_bar.value < progress_bar.max_value


func _on_player_enter_dock(player_: RoboVac, _dock: Dock) -> void:
	self.player = player_
	if not player.just_spawned:
		self.visible = true


func _on_player_exit_dock(_player: RoboVac, _dock: Dock) -> void:
	self.visible = false


func _on_player_dust_storage_changed(amount: float) -> void:
	progress_bar.value = amount
	update_progress()


func _on_button_close_pressed() -> void:
	self.visible = false


func _on_button_sleep_pressed() -> void:
	player.respawn(false, true)
	progress_bar.value = 0
	current_objective = current_objective * 2

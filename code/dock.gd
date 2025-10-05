class_name Dock extends Node3D

@onready var ring_particles: CPUParticles3D = %RingParticles

signal on_player_dock_enter()
signal on_player_dock_leave()

func _on_detector_body_entered(body: Node3D) -> void:
	if body is RoboVac:
		var player := body as RoboVac
		player.current_dock = self
		on_player_dock_enter.emit()
		ring_particles.emitting = true
		

func _on_detector_body_exited(body: Node3D) -> void:
	if body is RoboVac:
		var player := body as RoboVac
		player.current_dock = null
		on_player_dock_leave.emit()
		ring_particles.emitting = false

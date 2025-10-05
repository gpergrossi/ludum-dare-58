class_name Dock extends Node3D

@onready var ring_particles: CPUParticles3D = %RingParticles

func _on_detector_body_entered(body: Node3D) -> void:
	if body is RoboVac:
		var player := body as RoboVac
		player.notify_enter_dock(self)
		ring_particles.emitting = true
		

func _on_detector_body_exited(body: Node3D) -> void:
	if body is RoboVac:
		var player := body as RoboVac
		player.notify_exit_dock(self)
		ring_particles.emitting = false

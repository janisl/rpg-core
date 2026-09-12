extends PlayerStateBehaviour

signal landed()
signal handle_ground_physics(delta: float)


func _on_state_entered() -> void:
	landed.emit()


func _on_state_physics_processing(delta: float) -> void:
	handle_ground_physics.emit(delta)

extends PlayerStateBehaviour

signal handle_swimming_physics(delta: float)

func _on_state_physics_processing(delta: float) -> void:
	handle_swimming_physics.emit(delta)

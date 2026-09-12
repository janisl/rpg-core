extends PlayerStateBehaviour

signal handle_airborne_physics(delta: float)


func _on_state_physics_processing(delta: float) -> void:
	handle_airborne_physics.emit(delta)

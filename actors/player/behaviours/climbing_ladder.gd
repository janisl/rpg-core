extends PlayerStateBehaviour

signal handle_ladder_physics(delta: float)


func _on_state_physics_processing(delta: float) -> void:
	handle_ladder_physics.emit(delta)

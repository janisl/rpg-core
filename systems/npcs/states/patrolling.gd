extends NpcStateProcessor


func _on_patrolling_state_entered() -> void:
	_enter_state()


func _on_patrolling_state_exited() -> void:
	_exit_state()


func _on_patrolling_state_physics_processing(delta: float) -> void:
		return

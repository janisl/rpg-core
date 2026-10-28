extends NpcStateProcessor


func _on_searching_state_entered() -> void:
	_enter_state()


func _on_searching_state_exited() -> void:
	_exit_state()


func _on_searching_state_physics_processing(delta: float) -> void:
	state_chart.send_event("idle")

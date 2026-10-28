extends NpcStateProcessor


func _on_idle_state_entered() -> void:
	_enter_state()
	state_chart.send_event("ubody_neutral")


func _on_idle_state_exited() -> void:
	_exit_state()


func _on_idle_state_physics_processing(delta: float) -> void:
	npc.move_and_slide()

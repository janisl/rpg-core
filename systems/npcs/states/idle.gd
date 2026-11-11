extends NpcStateProcessor


func _on_idle_state_entered() -> void:
	_enter_state()
	npc.set_upper_body_neutral()
	if npc.has_patrol_path():
		state_chart.send_event("patrol")
		npc.set_lower_body_walk()


func _on_idle_state_exited() -> void:
	_exit_state()


func _on_idle_state_physics_processing(delta: float) -> void:
	npc.stop_moving(delta)

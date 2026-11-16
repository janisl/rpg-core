extends NpcStateProcessor


func _on_idle_state_entered() -> void:
	_enter_state()
	state_chart.send_event("ubody_neutral")
	if npc.patrol_path:
		state_chart.send_event("patrol")


func _on_idle_state_physics_processing(delta: float) -> void:
	npc.stop_moving(delta)

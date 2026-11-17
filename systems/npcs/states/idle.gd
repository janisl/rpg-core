extends NpcStateProcessor


func _on_idle_state_entered() -> void:
	_enter_state()
	npc.set_upper_body_neutral()
	if npc.has_patrol_path():
		state_chart.send_event("patrol")


func _on_idle_state_physics_processing(delta: float) -> void:
	npc.idle_action.physics_process(delta)

	if npc.sight_detection.is_suspicious_of_target():
		npc.set_sight_target(npc.sight_detection.detected_target.global_position)
		npc.state_chart.send_event("investigate")

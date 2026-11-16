extends NpcStateProcessor


func _on_alerted_state_entered() -> void:
	_enter_state()
	npc.alerted_action.start()


func _on_alerted_state_physics_processing(delta: float) -> void:
	if not npc.sight_attention_point.is_active and not npc.hearing_attention_point.is_active:
		npc.end_alert()
		state_chart.send_event("idle")
		return

	npc.alerted_action.physics_process(delta)

	if npc.sight_detection.is_suspicious_of_target():
		npc.end_alert()
		npc.set_sight_target(npc.sight_detection.detected_target.global_position)
		npc.state_chart.send_event("investigate")
	elif npc.alerted_action.has_given_up:
		npc.end_alert()
		state_chart.send_event("idle")

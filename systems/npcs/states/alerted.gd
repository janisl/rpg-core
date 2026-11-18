extends NpcStateProcessor


func _on_alerted_state_entered() -> void:
	npc.alerted_action.start()


func _on_alerted_state_physics_processing(delta: float) -> void:
	npc.alerted_action.physics_process(delta)
	if npc.is_investigating():
		npc.state_chart.send_event("investigate")
	elif npc.alerted_action.has_given_up:
		state_chart.send_event("idle")

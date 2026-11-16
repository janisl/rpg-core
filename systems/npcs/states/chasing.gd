extends NpcStateProcessor


func _on_chasing_state_entered() -> void:
	_enter_state()

	if not npc.has_valid_chase_target():
		state_chart.send_event("search")
		return

	npc.chase_action.start()


func _on_chasing_state_physics_processing(delta: float) -> void:
	if not npc.has_valid_chase_target():
		state_chart.send_event("idle")
		return

	var result := npc.chase_action.physics_process(delta)
	match result:
		NpcChaseAction.ChaseStatus.CAUGHT:
			state_chart.send_event("attack")

		NpcChaseAction.ChaseStatus.LOST:
			state_chart.send_event("search")

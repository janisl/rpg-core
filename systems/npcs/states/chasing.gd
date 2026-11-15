extends NpcStateProcessor


func _on_chasing_state_entered() -> void:
	_enter_state()

	if not npc.chase_target or npc.response_to_player == "Neutral":
		state_chart.send_event("search")
		state_chart.send_event("body_walk")
		return

	npc.chase_action.start()


func _on_chasing_state_physics_processing(delta: float) -> void:
	if not npc.chase_target or not (npc.chase_target as Player).health_attribute.is_alive:
		npc.stop_chasing()
		return

	npc.chase_action.physics_process(delta)

	match npc.chase_action._current_chase_status:
		npc.chase_action.ChaseStatus.CAUGHT:
			state_chart.send_event("attack")

		npc.chase_action.ChaseStatus.LOST:
			_start_searching()


func _start_searching() -> void:
	state_chart.send_event("search")
	state_chart.send_event("body_walk")

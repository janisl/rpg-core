extends NpcStateProcessor


func _on_chasing_state_entered() -> void:
	_enter_state()

	if not npc.is_hostile_towards(npc.chase_target):
		state_chart.send_event("search")
		return

	npc.chase_action.start()


func _on_chasing_state_physics_processing(delta: float) -> void:
	if not npc.is_hostile_towards(npc.chase_target):
		npc.stop_chasing()
		return

	var result := npc.chase_action.physics_process(delta)
	match result:
		NpcChaseAction.ChaseStatus.CAUGHT:
			state_chart.send_event("attack")

		NpcChaseAction.ChaseStatus.LOST:
			state_chart.send_event("search")

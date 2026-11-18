extends NpcStateProcessor


func _on_chasing_state_entered() -> void:
	npc.chase_action.start()


func _on_chasing_state_physics_processing(delta: float) -> void:
	var result := npc.chase_action.physics_process(delta)
	match result:
		NpcChaseAction.ChaseStatus.CAUGHT:
			npc.in_attack = true
			state_chart.send_event("attack")

		NpcChaseAction.ChaseStatus.LOST:
			state_chart.send_event("search")

extends NpcStateProcessor


func _on_patrolling_state_entered() -> void:
	_enter_state()
	npc.patrol_action.start()


func _on_patrolling_state_physics_processing(delta: float) -> void:
	var bumped_target := npc.patrol_action.check_for_bumping_into_hostile()
	if bumped_target:
		npc.start_chasing(bumped_target)
		state_chart.send_event("chase")

	npc.patrol_action.physics_process(delta)

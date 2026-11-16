extends NpcStateProcessor


func _on_patrolling_state_entered() -> void:
	_enter_state()
	npc.patrol_action.start()


func _on_patrolling_state_physics_processing(delta: float) -> void:
	var bumped_target := npc.patrol_action.check_for_bumping_into_hostile()
	if bumped_target:
		npc.start_chasing(bumped_target)
		state_chart.send_event("chase")
	elif npc.sight_detection.is_suspicious_of_target():
		npc.set_sight_target(npc.sight_detection.detected_target.global_position)
		npc.state_chart.send_event("investigate")

	npc.patrol_action.physics_process(delta)

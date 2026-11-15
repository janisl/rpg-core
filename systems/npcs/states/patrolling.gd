extends NpcStateProcessor


func _on_patrolling_state_entered() -> void:
	assert(npc.patrol_path, "Entered patrol state without patrol path")

	_enter_state()
	state_chart.send_event("ubody_neutral")

	npc.patrol_action._resume_patrolling()


func _on_patrolling_state_physics_processing(delta: float) -> void:
	for i in npc.get_slide_collision_count():
		var collision := npc.get_slide_collision(i)
		if collision.get_collider() is Player and npc.response_to_player == "Hostile":
			npc.start_chasing(collision.get_collider())

	match npc.patrol_action._current_travel_status:
		npc.patrol_action.TravelStatus.WAITING:
			npc.stop_moving(delta)
			return
		npc.patrol_action.TravelStatus.RUNNING:
			npc.patrol_action._running(delta)

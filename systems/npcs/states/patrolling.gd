extends NpcStateProcessor


func _on_patrolling_state_entered() -> void:
	assert(npc.patrol_path, "Entered patrol state without patrol path")

	_enter_state()
	state_chart.send_event("ubody_neutral")

	npc.nav_agent.target_position = _set_next_patrol_point_destination()


func _on_patrolling_state_exited() -> void:
	_exit_state()


func _on_patrolling_state_physics_processing(delta: float) -> void:
		return


func _set_next_patrol_point_destination() -> Vector3:
	return npc.patrol_path.target_next_patrol_point().global_position

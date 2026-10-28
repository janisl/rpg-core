extends NpcStateProcessor

enum TravelStatus { RUNNING, WAITING }

var _current_travel_status: TravelStatus


func _on_patrolling_state_entered() -> void:
	assert(npc.patrol_path, "Entered patrol state without patrol path")

	_enter_state()
	state_chart.send_event("ubody_neutral")

	npc.nav_agent.target_position = _set_next_patrol_point_destination()
	_current_travel_status = TravelStatus.RUNNING


func _on_patrolling_state_exited() -> void:
	_exit_state()


func _on_patrolling_state_physics_processing(delta: float) -> void:
	match _current_travel_status:
		TravelStatus.RUNNING:
			_running(delta)


func _set_next_patrol_point_destination() -> Vector3:
	return npc.patrol_path.target_next_patrol_point().global_position


func _running(delta: float) -> void:
	if not npc.nav_agent.is_target_reachable():
		npc.nav_agent.target_position = npc.patrol_path.starting_patrol_point.global_position

	npc.move_npc_to_next_position(delta)

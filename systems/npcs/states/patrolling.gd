extends NpcStateProcessor


func _enter_tree() -> void:
	await get_tree().process_frame
	npc.patrol_action._patrol_wait_timer = Timer.new()
	npc.patrol_action._patrol_wait_timer.wait_time = npc.patrol_action.patrol_point_wait_time
	npc.patrol_action._patrol_wait_timer.one_shot = true
	npc.patrol_action._patrol_wait_timer.timeout.connect(_resume_patrolling)
	add_child(npc.patrol_action._patrol_wait_timer)


func _on_patrolling_state_entered() -> void:
	assert(npc.patrol_path, "Entered patrol state without patrol path")

	_enter_state()
	state_chart.send_event("ubody_neutral")

	_resume_patrolling()


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
			_running(delta)


func _running(delta: float) -> void:
	if not npc.nav_agent.is_target_reachable():
		npc.nav_agent.target_position = npc.patrol_path.starting_patrol_point.global_position

	if npc.nav_agent.is_navigation_finished():
		_wait_at_patrol_point()
		return

	npc.move_npc_to_next_position(delta)


func _wait_at_patrol_point() -> void:
	npc.patrol_action._patrol_wait_timer.start()
	npc.patrol_action._current_travel_status = npc.patrol_action.TravelStatus.WAITING


func _resume_patrolling() -> void:
	npc.nav_agent.target_position = _set_next_patrol_point_destination()
	npc.patrol_action._current_travel_status = npc.patrol_action.TravelStatus.RUNNING


func _set_next_patrol_point_destination() -> Vector3:
	return npc.patrol_path.target_next_patrol_point().global_position

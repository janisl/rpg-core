extends NpcStateProcessor


func _enter_tree() -> void:
	await get_tree().process_frame
	npc.chase_action._chase_wait_timer = Timer.new()
	npc.chase_action._chase_wait_timer.wait_time = npc.chase_action.giveup_chase_time
	npc.chase_action._chase_wait_timer.one_shot = true
	npc.chase_action._chase_wait_timer.timeout.connect(_stop_chasing)
	add_child(npc.chase_action._chase_wait_timer)

	npc.chase_action._los_broken_timer = Timer.new()
	npc.chase_action._los_broken_timer.wait_time = npc.chase_action.wait_after_broken_los_time
	npc.chase_action._los_broken_timer.one_shot = true
	npc.chase_action._los_broken_timer.timeout.connect(_start_searching)
	add_child(npc.chase_action._los_broken_timer)


func _on_chasing_state_entered() -> void:
	_enter_state()

	if not npc.chase_target or npc.response_to_player == "Neutral":
		state_chart.send_event("search")
		state_chart.send_event("body_walk")
		return

	state_chart.send_event("body_run")
	state_chart.send_event("ubody_raise_weapon")
	npc.move_speed = npc.sprint_speed
	npc.chase_action._current_chase_status = npc.chase_action.ChaseStatus.CHASING
	npc.head_turner.target_node = npc.chase_target.get_path()


func _on_chasing_state_physics_processing(delta: float) -> void:
	npc.chase_action._can_see_player = npc.sight_detection.check_if_player_in_los()
	if npc.chase_action._can_see_player:
		npc.head_turner.active = true
		npc.chase_action._los_broken_timer.stop()
	else:
		npc.head_turner.active = false
		if npc.chase_action._los_broken_timer.is_stopped() and npc.chase_action._chase_wait_timer.is_stopped():
			npc.broken_los_point = npc.chase_target.global_position
			npc.chase_action._los_broken_timer.start()

	if not npc.chase_target or not (npc.chase_target as Player).health_attribute.is_alive:
		npc.stop_chasing()
		return

	if npc.is_dead():
		_npc_has_died()

	match npc.chase_action._current_chase_status:
		npc.chase_action.ChaseStatus.CHASING:
			_running(delta)
			return

		npc.chase_action.ChaseStatus.CAUGHT:
			state_chart.send_event("attack")
			return

		npc.chase_action.ChaseStatus.WAITING:
			npc.stop_moving(delta)

			if npc.chase_action.face_target_while_waiting:
				npc.face_direction(npc.chase_target.global_position)

			npc.nav_agent.target_position = npc.chase_target.global_position
			if npc.nav_agent.is_target_reachable() or npc.chase_action._can_see_player:
				npc.chase_action._chase_wait_timer.stop()
				npc.chase_action._current_chase_status = npc.chase_action.ChaseStatus.CHASING
			return

		npc.chase_action.ChaseStatus.LOST:
			_start_searching()
			return


func _running(delta: float) -> void:
	npc.nav_agent.target_position = npc.chase_target.global_position
	var distance_to_target := npc.global_position.distance_to(npc.chase_target.global_position)

	if npc.chase_action._can_see_player:
		var ranged_distance := _get_wieldable_range()
		if ranged_distance > 0 and distance_to_target <= ranged_distance - npc.chase_action.target_ranged_distance_offset:
			npc.chase_action._current_chase_status = npc.chase_action.ChaseStatus.CAUGHT
		elif distance_to_target <= npc.chase_action.target_melee_distance:
			npc.chase_action._current_chase_status = npc.chase_action.ChaseStatus.CAUGHT

	if not npc.nav_agent.is_target_reachable():
		_start_waiting()

	npc.move_npc_to_next_position(delta)


func _get_wieldable_range() -> float:
	if npc.is_using_weapon():
		return npc.get_weapon_range()
	return 0


func _start_waiting() -> void:
	npc.chase_action._current_chase_status = npc.chase_action.ChaseStatus.WAITING
	npc.chase_action._chase_wait_timer.start()


func _stop_chasing() -> void:
	npc.move_speed = npc.walk_speed
	npc.chase_action._current_chase_status = npc.chase_action.ChaseStatus.LOST


func _npc_has_died() -> void:
	npc.chase_action._current_chase_status = npc.chase_action.ChaseStatus.LOST


func _start_searching() -> void:
	var sight := npc.sight_detection
	sight.current_suspicion -= sight.aggro_threshold / 4
	npc.last_known_player_point = npc.last_reachable_path
	state_chart.send_event("search")
	state_chart.send_event("body_walk")

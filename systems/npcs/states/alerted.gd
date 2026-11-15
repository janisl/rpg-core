extends NpcStateProcessor


func _enter_tree() -> void:
	await get_tree().process_frame
	npc.alerted_action._shock_timer = _create_timer(npc.alerted_action.initial_shock_time, _start_moving)
	npc.alerted_action._return_to_patrol_timer = _create_timer(npc.alerted_action.wait_time_once_reached, _return_to_patrol)


func _on_alerted_state_entered() -> void:
	_enter_state()
	npc.alerted_action._shock_timer.start()
	if npc.sight_attention_point.is_active:
		npc.alerted_action._target = npc.sight_attention_point.global_position
	elif npc.hearing_attention_point.is_active:
		npc.alerted_action._target = npc.hearing_attention_point.global_position
	play_sound(npc.sounds.alerted_sound)


func _on_alerted_state_physics_processing(delta: float) -> void:
	if not npc.sight_attention_point.is_active and not npc.hearing_attention_point.is_active:
		state_chart.send_event("idle")
		return

	if not npc.alerted_action._shock_timer.is_stopped() or not npc.alerted_action._return_to_patrol_timer.is_stopped():
		npc.face_direction(npc.alerted_action._target)

	if npc.nav_agent.target_position == npc.alerted_action._target and not npc.nav_agent.is_target_reached():
		npc.move_npc_to_next_position(delta)
	else:
		npc.stop_moving(delta)

	if (npc.nav_agent.is_target_reached() or not npc.nav_agent.is_target_reachable()) and npc.alerted_action._return_to_patrol_timer.is_stopped():
		npc.alerted_action._return_to_patrol_timer.start()


func _start_moving() -> void:
	npc.nav_agent.target_position = npc.alerted_action._target


func _return_to_patrol() -> void:
	state_chart.send_event("idle")
	play_sound(npc.sounds.must_have_been_the_wind_sound)


func _create_timer(wait_time: float, call_on_timeout: Callable) -> Timer:
	var timer := Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(call_on_timeout)
	add_child(timer)
	return timer

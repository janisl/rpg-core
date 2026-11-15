extends NpcStateProcessor


func _enter_tree() -> void:
	await get_tree().process_frame
	if npc.search_action.show_search_points:
		npc.search_action._search_point_one_label = _create_debug_label("1")
		npc.search_action._search_point_two_label = _create_debug_label("2")

	npc.search_action._first_wait_timer = _create_timer(npc.search_action.wait_at_first_point, _search_next_point)
	npc.search_action._second_wait_timer = _create_timer(npc.search_action.end_search_after_second_point, _end_search)
	npc.search_action._reacquire_timer = _create_timer(npc.search_action.reacquire_time, _start_chasing)
	npc.search_action._stuck_timer = _create_timer(npc.search_action.end_search_if_stuck_for, _end_search)


func _on_searching_state_entered() -> void:
	_enter_state()
	if npc.search_action.show_search_points and not npc.search_action._search_point_one_label.is_inside_tree():
			get_tree().current_scene.add_child(npc.search_action._search_point_one_label)
			get_tree().current_scene.add_child(npc.search_action._search_point_two_label)

	npc.nav_agent.target_position = npc.search_action.broken_los_point
	npc.nav_agent.target_reached.connect(_on_reached_target)

	play_sound(npc.sounds.searching_sound)
	state_chart.send_event("body_walk")
	npc.move_speed = npc.walk_speed
	npc.search_action._los_point_reached = false
	npc.search_action._last_known_point_reached = false
	npc.search_action._head = npc.head_turner
	npc.search_action._head.active = true
	npc.search_action._head.target_node = npc.search_action.searching_look_ahead.get_path()


func _on_searching_state_exited() -> void:
	npc.nav_agent.target_reached.disconnect(_on_reached_target)

	npc.search_action._first_wait_timer.stop()
	npc.search_action._second_wait_timer.stop()
	npc.search_action._reacquire_timer.stop()
	npc.search_action._stuck_timer.stop()

	npc.search_action.searching_look_ahead_pivot.rotation_degrees.y = 0
	npc.search_action._head.target_node = NodePath("")

	if npc.search_action.show_search_points:
		npc.search_action._search_point_one_label.visible = false
		npc.search_action._search_point_two_label.visible = false


func _on_searching_state_physics_processing(delta: float) -> void:
	if npc.search_action.show_search_points:
		npc.search_action._search_point_one_label.visible = true
		npc.search_action._search_point_one_label.global_position = npc.search_action.broken_los_point
		npc.search_action._search_point_two_label.visible = true
		npc.search_action._search_point_two_label.global_position = npc.search_action.last_known_player_point

	_sight_detection_check()
	if npc.nav_agent.is_target_reached():
		npc.stop_moving(delta)
	else:
		if npc.search_action._reacquire_timer.is_stopped():
			_turn_head(delta)
			npc.move_npc_to_next_position(delta)

		if not npc.nav_agent.is_target_reachable() and npc.search_action._stuck_timer.is_stopped():
			npc.search_action._stuck_timer.start()


func _sight_detection_check() -> void:
	if npc.search_action.sight_detection.check_if_player_in_los():
		npc.search_action._stuck_timer.stop()
		if npc.search_action._reacquire_timer.is_stopped():
			npc.search_action._head.target_node = npc.chase_target.head.get_path()
			play_sound(npc.sounds.i_see_you_sound)
			npc.search_action._reacquire_timer.start()
	else:
		npc.search_action._head.target_node = npc.search_action.searching_look_ahead.get_path()
		npc.search_action._reacquire_timer.stop()


func _start_chasing() -> void:
	state_chart.send_event("chase")


func _on_reached_target() -> void:
	if not npc.search_action._los_point_reached:
		npc.search_action._los_point_reached = true
		npc.search_action._first_wait_timer.start()
	elif not npc.search_action._last_known_point_reached:
		npc.search_action._last_known_point_reached = true
		npc.search_action._second_wait_timer.start()


func _search_next_point() -> void:
	npc.nav_agent.target_position = npc.search_action.last_known_player_point


func _end_search() -> void:
	play_sound(npc.sounds.end_search_sound)
	if npc.search_action.reset_suspicion_when_search_ends:
		if npc.hearing_detection:
			npc.hearing_detection.reset()
		if npc.sight_detection:
			npc.sight_detection.reset()
	npc.stop_chasing()


func _turn_head(delta: float) -> void:
	if npc.search_action.head_target_rotation_angle > 0:
		npc.search_action.searching_look_ahead_pivot.rotate_y(deg_to_rad(180) * delta)
		if npc.search_action.searching_look_ahead_pivot.rotation_degrees.y >= npc.search_action.head_target_rotation_angle:
			npc.search_action.head_target_rotation_angle *= -1
	else:
		npc.search_action.searching_look_ahead_pivot.rotate_y(deg_to_rad(-180) * delta)
		if npc.search_action.searching_look_ahead_pivot.rotation_degrees.y <= npc.search_action.head_target_rotation_angle:
			npc.search_action.head_target_rotation_angle *= -1


func _create_timer(wait_time: float, call_on_timeout: Callable) -> Timer:
	var timer := Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(call_on_timeout)
	add_child(timer)
	return timer


func _create_debug_label(text: String) -> Label3D:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.text = text
	return label

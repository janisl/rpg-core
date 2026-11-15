extends NpcStateProcessor


func _enter_tree() -> void:
	await get_tree().process_frame
	npc.search_action._second_wait_timer = npc.search_action._create_timer(npc.search_action.end_search_after_second_point, _end_search)
	npc.search_action._reacquire_timer = npc.search_action._create_timer(npc.search_action.reacquire_time, _start_chasing)
	npc.search_action._stuck_timer = npc.search_action._create_timer(npc.search_action.end_search_if_stuck_for, _end_search)


func _on_searching_state_entered() -> void:
	_enter_state()
	if npc.search_action.show_search_points and not npc.search_action._search_point_one_label.is_inside_tree():
			get_tree().current_scene.add_child(npc.search_action._search_point_one_label)
			get_tree().current_scene.add_child(npc.search_action._search_point_two_label)

	npc.nav_agent.target_position = npc.broken_los_point
	npc.nav_agent.target_reached.connect(npc.search_action._on_reached_target)

	play_sound(npc.sounds.searching_sound)
	state_chart.send_event("body_walk")
	npc.move_speed = npc.walk_speed
	npc.search_action._los_point_reached = false
	npc.search_action._last_known_point_reached = false
	npc.search_action._head = npc.head_turner
	npc.search_action._head.active = true
	npc.search_action._head.target_node = npc.search_action.searching_look_ahead.get_path()


func _on_searching_state_exited() -> void:
	npc.nav_agent.target_reached.disconnect(npc.search_action._on_reached_target)

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
		npc.search_action._search_point_one_label.global_position = npc.broken_los_point
		npc.search_action._search_point_two_label.visible = true
		npc.search_action._search_point_two_label.global_position = npc.last_known_player_point

	npc.search_action._sight_detection_check()
	if npc.nav_agent.is_target_reached():
		npc.stop_moving(delta)
	else:
		if npc.search_action._reacquire_timer.is_stopped():
			npc.search_action._turn_head(delta)
			npc.move_npc_to_next_position(delta)

		if not npc.nav_agent.is_target_reachable() and npc.search_action._stuck_timer.is_stopped():
			npc.search_action._stuck_timer.start()


func _start_chasing() -> void:
	state_chart.send_event("chase")


func _end_search() -> void:
	play_sound(npc.sounds.end_search_sound)
	if npc.search_action.reset_suspicion_when_search_ends:
		if npc.hearing_detection:
			npc.hearing_detection.reset()
		if npc.sight_detection:
			npc.sight_detection.reset()
	npc.stop_chasing()

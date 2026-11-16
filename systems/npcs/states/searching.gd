extends NpcStateProcessor


func _enter_tree() -> void:
	await get_tree().process_frame
	npc.search_action._second_wait_timer = npc.search_action._create_timer(npc.search_action.end_search_after_second_point, _end_search)
	npc.search_action._reacquire_timer = npc.search_action._create_timer(npc.search_action.reacquire_time, _start_chasing)
	npc.search_action._stuck_timer = npc.search_action._create_timer(npc.search_action.end_search_if_stuck_for, _end_search)


func _on_searching_state_entered() -> void:
	_enter_state()
	npc.search_action.start()


func _on_searching_state_exited() -> void:
	npc.search_action.stop()


func _on_searching_state_physics_processing(delta: float) -> void:
	npc.search_action.physics_process(delta)


func _start_chasing() -> void:
	state_chart.send_event("chase")


func _end_search() -> void:
	play_sound(npc.sounds.end_search_sound)
	if npc.search_action.reset_suspicion_when_search_ends:
		if npc.hearing_detection:
			npc.hearing_detection.reset()
		if npc.sight_detection:
			npc.sight_detection.reset()
	npc.chase_target = null
	state_chart.send_event("idle")

extends NpcStateProcessor


func _enter_tree() -> void:
	await get_tree().process_frame
	npc.alerted_action._give_up_timer = npc.alerted_action._create_timer(npc.alerted_action.wait_time_once_reached, _give_up)


func _on_alerted_state_entered() -> void:
	_enter_state()
	npc.alerted_action.start()


func _on_alerted_state_physics_processing(delta: float) -> void:
	if not npc.sight_attention_point.is_active and not npc.hearing_attention_point.is_active:
		state_chart.send_event("idle")
		return

	npc.alerted_action.physics_process(delta)

	if npc.sight_detection.is_suspicious_of_target():
		npc.set_sight_target(npc.sight_detection.detected_target.global_position)
		npc.state_chart.send_event("investigate")


func _give_up() -> void:
	state_chart.send_event("idle")
	play_sound(npc.sounds.must_have_been_the_wind_sound)

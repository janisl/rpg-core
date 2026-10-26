extends NpcStateProcessor


func _on_chasing_state_entered() -> void:
	_enter_state()
	state_chart.send_event("body_run")
	state_chart.send_event("ubody_raise_weapon")


func _on_chasing_state_exited() -> void:
	_exit_state()


func _on_chase_state_physics_processing(delta: float) -> void:
	npc.move_and_slide()

	if not npc.attention_target:
		return

	npc.nav_agent.target_position = npc.attention_target.global_position

	var distance = npc.global_position.distance_to(npc.attention_target.global_position)
	var ranged_distance := _get_wieldable_range()
	if ranged_distance > 0 && distance < ranged_distance:
		npc.nav_agent.velocity = Vector3.ZERO
		state_chart.send_event("onMelee")
		return
	elif distance <= npc.melee_range:
		npc.nav_agent.velocity = Vector3.ZERO
		state_chart.send_event("onMelee")
		return

	if npc.nav_agent.is_navigation_finished():
		npc.nav_agent.velocity = Vector3.ZERO
		return

	var next_pos := npc.nav_agent.get_next_path_position() as Vector3
	var direction := npc.global_position.direction_to(next_pos)

	npc.nav_agent.velocity = direction * npc.sprint_speed
	if not npc.nav_agent.avoidance_enabled:
		npc._on_velocity_computed(npc.nav_agent.velocity)

	npc.face_direction(next_pos)


func _get_wieldable_range() -> float:
	if npc.is_using_weapon():
		return npc.get_weapon_range()
	return 0

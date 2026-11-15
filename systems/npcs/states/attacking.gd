extends NpcStateProcessor


func _on_attacking_state_entered() -> void:
	_enter_state()
	if not npc.chase_target:
		state_chart.send_event("chase")
	else:
		npc.attack_action._count_down = npc.attack_action.attack_duration
		if _attack_while_moving():
			_attempt_attack()


func _on_attacking_state_exited() -> void:
	npc.attack_action.attack_impact_zone.set_collision(false)


func _on_attacking_state_physics_processing(delta: float) -> void:
	npc.stop_moving(delta)
	if npc.chase_target:
		npc.face_direction(npc.chase_target.global_position)

	if npc.attack_action._count_down <= 0 and _attack_while_moving():
		_attempt_attack()
		state_chart.send_event("chase")
	else:
		npc.attack_action._count_down -= delta


func _attack_while_moving() -> bool:
	if npc.attack_action.can_attack_while_moving or not npc.is_using_weapon():
		return true
	return npc.velocity.length_squared() == 0


func _attempt_attack() -> void:
	if not npc.is_using_weapon():
		npc.attack_action._count_down = npc.attack_action.attack_duration
		state_chart.send_event("ubody_attack")
		_punch_attack()
	else:
		npc.attack_action._count_down = npc.attack_action.attack_duration
		npc.sight_detection.check_if_player_in_los()
		npc.do_weapon_attack()


func _punch_attack() -> void:
	AudioManager.play_sound_3d(npc.sounds.attack_sound, npc.global_position)

	npc.attack_action.attack_impact_zone.set_collision(true)

extends NpcStateProcessor


func _on_attacking_state_entered() -> void:
	_enter_state()
	if not npc.chase_target:
		state_chart.send_event("chase")
	else:
		npc.attack_action._count_down = npc.attack_action.attack_duration
		npc.attack_action._did_attack = false


func _on_attacking_state_exited() -> void:
	npc.attack_action.attack_impact_zone.set_collision(false)


func _on_attacking_state_physics_processing(delta: float) -> void:
	npc.stop_moving(delta)
	if npc.chase_target:
		npc.face_direction(npc.chase_target.global_position)

	if not npc.attack_action._did_attack and npc.attack_action._can_attack_now():
		npc.attack_action._attempt_attack()
		npc.attack_action._did_attack = true

	if npc.attack_action._count_down <= 0:
		state_chart.send_event("chase")
	else:
		npc.attack_action._count_down -= delta

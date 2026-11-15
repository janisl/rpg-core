extends NpcStateProcessor


func _on_investigate_state_entered() -> void:
	_enter_state()
	state_chart.send_event("ubody_raise_weapon")
	if npc.sight_attention_point.is_active:
		npc.investigate_action._attention_spot = npc.sight_attention_point.global_position
		npc.nav_agent.target_position = npc.investigate_action._attention_spot
	elif npc.hearing_attention_point.is_active:
		npc.investigate_action._attention_spot = npc.hearing_attention_point.global_position
		npc.nav_agent.target_position = npc.investigate_action._attention_spot
	play_sound(npc.sounds.investigate_sound)


func _on_investigate_state_physics_processing(delta: float) -> void:
	npc.move_npc_to_next_position(delta)

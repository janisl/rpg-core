extends NpcStateProcessor

var _attention_spot: Vector3


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"attention_spot"] = _attention_spot
	return state


func load_state(state: Dictionary) -> void:
	_attention_spot = state.get(&"attention_spot", Vector3.ZERO)


func _on_investigate_state_entered() -> void:
	_enter_state()
	state_chart.send_event("ubody_raise_weapon")
	if npc.sight_attention_point.is_active:
		_attention_spot = npc.sight_attention_point.global_position
		npc.nav_agent.target_position = _attention_spot
	elif npc.hearing_attention_point.is_active:
		_attention_spot = npc.hearing_attention_point.global_position
		npc.nav_agent.target_position = _attention_spot
	play_sound(npc.sounds.investigate_sound)


func _on_investigating_state_exited() -> void:
	_exit_state()


func _on_investigate_state_physics_processing(delta: float) -> void:
	npc.move_npc_to_next_position(delta)

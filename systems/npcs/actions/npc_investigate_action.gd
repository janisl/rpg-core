class_name NpcInvestigateAction
extends Node

var _attention_spot: Vector3

@onready var npc: Npc = $".."


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"attention_spot"] = _attention_spot
	return state


func load_state(state: Dictionary) -> void:
	_attention_spot = state.get(&"attention_spot", Vector3.ZERO)


func start() -> void:
	npc.state_chart.send_event("ubody_raise_weapon")
	if npc.sight_attention_point.is_active:
		_attention_spot = npc.sight_attention_point.global_position
		npc.nav_agent.target_position = _attention_spot
	elif npc.hearing_attention_point.is_active:
		_attention_spot = npc.hearing_attention_point.global_position
		npc.nav_agent.target_position = _attention_spot
	npc.play_sound(npc.sounds.investigate_sound)


func physics_process(delta: float) -> void:
	npc.move_npc_to_next_position(delta)

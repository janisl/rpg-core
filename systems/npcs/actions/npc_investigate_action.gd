class_name NpcInvestigateAction
extends Node

enum Result { RUNNING, FOUND, NOTHING }

var _attention_spot: Vector3

@onready var npc: Npc = $".."


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"attention_spot"] = _attention_spot
	return state


func load_state(state: Dictionary) -> void:
	_attention_spot = state.get(&"attention_spot", Vector3.ZERO)


func start() -> void:
	npc.set_upper_body_raised_weapon()
	if npc.sight_attention_point.is_active:
		_attention_spot = npc.sight_attention_point.global_position
		npc.nav_agent.target_position = _attention_spot
	elif npc.hearing_attention_point.is_active:
		_attention_spot = npc.hearing_attention_point.global_position
		npc.nav_agent.target_position = _attention_spot
	npc.play_sound(npc.sounds.investigate_sound)


func physics_process(delta: float) -> Result:
	npc.sight_detection.update_suspicion(delta, false)

	npc.move_npc_to_next_position(delta)

	if npc.sight_detection.is_aggro_to_target():
		npc.sight_detection.current_suspicion = npc.sight_detection.investigation_threshold
		npc.start_chasing(npc.sight_detection.detected_target)
		return Result.FOUND
	elif npc.sight_detection.current_suspicion <= 0 and npc.hearing_detection.current_suspicion <= 0:
		npc.sight_attention_point.is_active = false
		npc.hearing_attention_point.is_active = false
		return Result.NOTHING
	else:
		return Result.RUNNING

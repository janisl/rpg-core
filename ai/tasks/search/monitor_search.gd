@tool
extends NpcBTAction
## Runs alongside the searching behaviour. Builds up suspicion and gives up
## (FAILURE) when the target is no longer valid or the NPC has been unable to
## reach its search point for [member give_up_when_stuck_for] seconds.

@export var give_up_when_stuck_for := 10.0

var _stuck_time := 0.0


func _start() -> void:
	_stuck_time = 0.0


func _update(delta: float) -> Status:
	if not agent.has_valid_chase_target():
		agent.end_combat()
		return FAILURE

	agent.sight_detection.update_suspicion(delta, false)

	if agent.nav_agent.is_target_reachable():
		_stuck_time = 0.0
	else:
		_stuck_time += delta
		if _stuck_time >= give_up_when_stuck_for:
			agent.end_search()
			return FAILURE
	return RUNNING


func _end() -> void:
	agent.head_turner.target_node = NodePath("")


func _save_state() -> Dictionary:
	return { &"stuck_time": _stuck_time }


func _load_state(state: Dictionary) -> void:
	_stuck_time = state.get(&"stuck_time", 0.0)

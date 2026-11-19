@tool
extends NpcBTAction
## Runs alongside chasing and attacking. Tracks line of sight and gives up the
## chase (FAILURE) when the target is out of sight for [member lose_sight_after]
## seconds, or has had no path to it while out of sight for
## [member lose_unreachable_after] seconds. On giving up, it marks the target as
## lost and stores the points to search on the blackboard.

@export var lose_sight_after := 3.0
@export var lose_unreachable_after := 5.0

var _unseen_time := 0.0
var _unreachable_time := 0.0


func _start() -> void:
	_unseen_time = 0.0
	_unreachable_time = 0.0


func _update(delta: float) -> Status:
	if not agent.has_valid_chase_target() or agent.is_dead():
		return _lose_target()

	var can_see := agent.sight_detection.check_if_chase_target_in_los() as bool
	var reachable := agent.nav_agent.is_target_reachable() as bool
	agent.head_turner.active = can_see

	if can_see:
		_unseen_time = 0.0
		_unreachable_time = 0.0
		return RUNNING

	# Out of sight: remember where the target was last seen. While waiting for
	# a path, only an already started countdown keeps going.
	if _unseen_time == 0.0 and reachable:
		blackboard.set_var(&"search_point_1", agent.chase_target.global_position)
	if _unseen_time > 0.0 or reachable:
		_unseen_time += delta
	_unreachable_time = 0.0 if reachable else _unreachable_time + delta

	if _unseen_time >= lose_sight_after or _unreachable_time >= lose_unreachable_after:
		return _lose_target()
	return RUNNING


func _lose_target() -> Status:
	blackboard.set_var(&"target_lost", true)
	blackboard.set_var(&"search_point_2", agent.last_reachable_path)
	var sight: SightDetection = agent.sight_detection
	sight.current_suspicion -= sight.aggro_threshold / 4
	return FAILURE


func _save_state() -> Dictionary:
	return { &"unseen_time": _unseen_time, &"unreachable_time": _unreachable_time }


func _load_state(state: Dictionary) -> void:
	_unseen_time = state.get(&"unseen_time", 0.0)
	_unreachable_time = state.get(&"unreachable_time", 0.0)

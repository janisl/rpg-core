class_name NpcPatrolAction
extends Node

enum TravelStatus { RUNNING, WAITING }

@export var patrol_point_wait_time := 3.0

var _current_travel_status: TravelStatus

var _patrol_wait_timer: Timer


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"current_travel_status"] = _current_travel_status
	SaveUtils.save_timer(state, &"patrol_wait_timer", _patrol_wait_timer)
	return state


func load_state(state: Dictionary) -> void:
	_current_travel_status = state.get(&"current_travel_status", TravelStatus.RUNNING)
	SaveUtils.load_timer(state, &"patrol_wait_timer", _patrol_wait_timer)

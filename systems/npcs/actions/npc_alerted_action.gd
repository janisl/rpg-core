class_name NpcAlertedAction
extends Node

@export var initial_shock_time := 1.5
@export var wait_time_once_reached := 5.0

var _shock_timer: Timer
var _return_to_patrol_timer: Timer
var _target: Vector3


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_timer(state, &"shock_timer", _shock_timer)
	SaveUtils.save_timer(state, &"return_to_patrol_timer", _return_to_patrol_timer)
	state[&"target"] = _target
	return state


func load_state(state: Dictionary) -> void:
	SaveUtils.load_timer(state, &"shock_timer", _shock_timer)
	SaveUtils.load_timer(state, &"return_to_patrol_timer", _return_to_patrol_timer)
	_target = state.get(&"target", _target)

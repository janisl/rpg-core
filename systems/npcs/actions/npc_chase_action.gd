class_name NpcChaseAction
extends Node

enum ChaseStatus { CHASING, CAUGHT, WAITING, LOST }

@export var target_melee_distance := 1.5
@export var target_ranged_distance_offset := 1.0
@export var giveup_chase_time := 5.0
@export var wait_after_broken_los_time := 3.0
@export var face_target_while_waiting := true

var _chase_wait_timer: Timer
var _los_broken_timer: Timer
var _current_chase_status: ChaseStatus
var _can_see_player := false


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_timer(state, &"chase_wait_timer", _chase_wait_timer)
	SaveUtils.save_timer(state, &"los_broken_timer", _los_broken_timer)
	state[&"current_chase_status"] = _current_chase_status
	state[&"can_see_player"] = _can_see_player
	return state


func load_state(state: Dictionary) -> void:
	SaveUtils.load_timer(state, &"chase_wait_timer", _chase_wait_timer)
	SaveUtils.load_timer(state, &"los_broken_timer", _los_broken_timer)
	_current_chase_status = state.get(&"current_chase_status", ChaseStatus.CHASING)
	_can_see_player = state.get(&"can_see_player", false)

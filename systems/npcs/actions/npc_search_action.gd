class_name NpcSearchAction
extends Node

@export var sight_detection: SightDetection
@export var searching_look_ahead_pivot: Node3D
@export var searching_look_ahead: Node3D

@export var reacquire_time := 0.5
@export var head_target_rotation_angle := 60.0
@export var reset_suspicion_when_search_ends := true
@export var wait_at_first_point := 5.0
@export var end_search_after_second_point := 3.0
@export var end_search_if_stuck_for := 10.0

@export var show_search_points := false

var _search_point_one_label: Label3D
var _search_point_two_label: Label3D

var _los_point_reached := false
var _last_known_point_reached := false

var _reacquire_timer: Timer
var _first_wait_timer: Timer
var _second_wait_timer: Timer
var _stuck_timer: Timer

var _head: LookAtModifier3D


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"los_point_reached"] = _los_point_reached
	state[&"_last_known_point_reached"] = _last_known_point_reached
	SaveUtils.save_timer(state, &"reacquire_timer", _reacquire_timer)
	SaveUtils.save_timer(state, &"first_wait_timer", _first_wait_timer)
	SaveUtils.save_timer(state, &"second_wait_timer", _second_wait_timer)
	SaveUtils.save_timer(state, &"stuck_timer", _stuck_timer)
	return state


func load_state(state: Dictionary) -> void:
	_los_point_reached = state.get(&"los_point_reached", false)
	_last_known_point_reached = state.get(&"last_known_point_reached", false)
	SaveUtils.load_timer(state, &"reacquire_timer", _reacquire_timer)
	SaveUtils.load_timer(state, &"first_wait_timer", _first_wait_timer)
	SaveUtils.load_timer(state, &"second_wait_timer", _second_wait_timer)
	SaveUtils.load_timer(state, &"stuck_timer", _stuck_timer)

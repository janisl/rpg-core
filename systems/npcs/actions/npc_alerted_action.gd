class_name NpcAlertedAction
extends Node

@export var initial_shock_time := 1.5
@export var wait_time_once_reached := 5.0

var has_given_up: bool

var _started: bool
var _shock_timer: Timer
var _give_up_timer: Timer
var _target: Vector3

@onready var npc: Npc = $".."


func _enter_tree() -> void:
	_shock_timer = _create_timer(initial_shock_time, _start_moving)
	_give_up_timer = _create_timer(wait_time_once_reached, _give_up)


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"started"] = _started
	SaveUtils.save_timer(state, &"shock_timer", _shock_timer)
	SaveUtils.save_timer(state, &"give_up_timer", _give_up_timer)
	state[&"target"] = _target
	state[&"has_given_up"] = has_given_up
	return state


func load_state(state: Dictionary) -> void:
	_started = state.get(&"started", false)
	SaveUtils.load_timer(state, &"shock_timer", _shock_timer)
	SaveUtils.load_timer(state, &"give_up_timer", _give_up_timer)
	_target = state.get(&"target", _target)
	has_given_up = state.get(&"has_given_up", false)


func start() -> void:
	if _started:
		return
	_started = true
	has_given_up = false
	_shock_timer.start()
	if npc.sight_attention_point.is_active:
		_target = npc.sight_attention_point.global_position
	elif npc.hearing_attention_point.is_active:
		_target = npc.hearing_attention_point.global_position
	npc.play_sound(npc.sounds.alerted_sound)


func stop() -> void:
	_shock_timer.stop()
	_give_up_timer.stop()
	_started = false


func physics_process(delta: float) -> void:
	if not npc.sight_attention_point.is_active and not npc.hearing_attention_point.is_active:
		npc.end_alert()
		has_given_up = true
		return

	npc.sight_detection.update_suspicion(delta, false)

	if not _shock_timer.is_stopped() or not _give_up_timer.is_stopped():
		npc.face_direction(_target)

	if npc.nav_agent.target_position == _target and not npc.nav_agent.is_target_reached():
		npc.move_npc_to_next_position(delta)
	else:
		npc.stop_moving(delta)

	if (npc.nav_agent.is_target_reached() or not npc.nav_agent.is_target_reachable()) and _give_up_timer.is_stopped():
		_give_up_timer.start()

	if npc.sight_detection.is_suspicious_of_target():
		npc.set_sight_target(npc.sight_detection.detected_target.global_position)
		npc.start_investigating()


func _start_moving() -> void:
	npc.nav_agent.target_position = _target


func _give_up() -> void:
	has_given_up = true
	npc.play_sound(npc.sounds.must_have_been_the_wind_sound)
	npc.end_alert()


func _create_timer(wait_time: float, call_on_timeout: Callable) -> Timer:
	var timer := Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(call_on_timeout)
	add_child(timer)
	return timer

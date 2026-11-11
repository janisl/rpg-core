class_name NpcAlertedAction
extends Node

## Freezes in shock, walks to where the NPC was alerted from, looks around and then gives up.
## Holds no transition logic, so it can be driven by a state or a behaviour tree leaf.

signal gave_up

var npc: Npc
var initial_shock_time := 1.5
var wait_time_once_reached := 5.0

var _shock_timer: Timer
var _give_up_timer: Timer
var _target: Vector3
var _has_given_up := false


func _init(p_npc: Npc, p_initial_shock_time: float, p_wait_time_once_reached: float) -> void:
	npc = p_npc
	initial_shock_time = p_initial_shock_time
	wait_time_once_reached = p_wait_time_once_reached


func _enter_tree() -> void:
	_shock_timer = _create_timer(initial_shock_time, _start_moving)
	_give_up_timer = _create_timer(wait_time_once_reached, _give_up)


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_timer(state, &"shock_timer", _shock_timer)
	SaveUtils.save_timer(state, &"return_to_patrol_timer", _give_up_timer)
	state[&"target"] = _target
	state[&"has_given_up"] = _has_given_up
	return state


func load_state(state: Dictionary) -> void:
	SaveUtils.load_timer(state, &"shock_timer", _shock_timer)
	SaveUtils.load_timer(state, &"return_to_patrol_timer", _give_up_timer)
	_target = state.get(&"target", _target)
	_has_given_up = state.get(&"has_given_up", false)


func start() -> void:
	_has_given_up = false
	_shock_timer.start()
	_target = npc.attention_target.global_position


func has_given_up() -> bool:
	return _has_given_up


func physics_process(delta: float) -> void:
	if not _shock_timer.is_stopped() or not _give_up_timer.is_stopped():
		npc.face_direction(npc.attention_target.global_position)

	if npc.nav_agent.target_position == npc.attention_target.global_position and not npc.nav_agent.is_target_reached():
		npc.move_npc_to_next_position(delta)
	else:
		npc.stop_moving(delta)

	if (npc.nav_agent.is_target_reached() or not npc.nav_agent.is_target_reachable()) and _give_up_timer.is_stopped():
		_give_up_timer.start()


func _start_moving() -> void:
	npc.nav_agent.target_position = _target


func _give_up() -> void:
	_has_given_up = true
	gave_up.emit()


func _create_timer(wait_time: float, call_on_timeout: Callable) -> Timer:
	var timer := Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(call_on_timeout)
	add_child(timer)
	return timer

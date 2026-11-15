class_name NpcAlertedAction
extends Node

@export var initial_shock_time := 1.5
@export var wait_time_once_reached := 5.0

var _shock_timer: Timer
var _give_up_timer: Timer
var _target: Vector3

@onready var npc: Npc = $".."


func _enter_tree() -> void:
	_shock_timer = _create_timer(initial_shock_time, _start_moving)


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_timer(state, &"shock_timer", _shock_timer)
	SaveUtils.save_timer(state, &"give_up_timer", _give_up_timer)
	state[&"target"] = _target
	return state


func load_state(state: Dictionary) -> void:
	SaveUtils.load_timer(state, &"shock_timer", _shock_timer)
	SaveUtils.load_timer(state, &"give_up_timer", _give_up_timer)
	_target = state.get(&"target", _target)


func _start_moving() -> void:
	npc.nav_agent.target_position = _target


func _create_timer(wait_time: float, call_on_timeout: Callable) -> Timer:
	var timer := Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(call_on_timeout)
	add_child(timer)
	return timer

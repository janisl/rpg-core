class_name NpcSearchAction
extends Node

## Searches for a lost target: walks to where line of sight broke, waits, then walks to the
## last known target position, looking around on the way.
## Reads its search points from the NPC's search memory.
## Holds no transition logic, so it can be driven by a state or a behaviour tree leaf.

## Emitted when the target comes into sight, before the reacquire delay runs out.
signal target_spotted
## Emitted when the target stayed in sight for the reacquire delay.
signal target_reacquired
## Emitted when both search points were checked or the NPC got stuck.
signal search_ended

var npc: Npc
var sight_detection: SightDetection
var searching_look_ahead_pivot: Node3D
var searching_look_ahead: Node3D

var reacquire_time := 0.5
var head_target_rotation_angle := 60.0
var wait_at_first_point := 5.0
var end_search_after_second_point := 3.0
var end_search_if_stuck_for := 10.0

var show_search_points := false

var _search_point_one_label: Label3D
var _search_point_two_label: Label3D

var _los_point_reached := false
var _last_known_point_reached := false

var _reacquire_timer: Timer
var _first_wait_timer: Timer
var _second_wait_timer: Timer
var _stuck_timer: Timer

var _head: LookAtModifier3D


func _init(p_npc: Npc) -> void:
	npc = p_npc


func _enter_tree() -> void:
	if show_search_points:
		_search_point_one_label = _create_debug_label("1")
		_search_point_two_label = _create_debug_label("2")

	_first_wait_timer = _create_timer(wait_at_first_point, _search_next_point)
	_second_wait_timer = _create_timer(end_search_after_second_point, search_ended.emit)
	_reacquire_timer = _create_timer(reacquire_time, target_reacquired.emit)
	_stuck_timer = _create_timer(end_search_if_stuck_for, search_ended.emit)


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"los_point_reached"] = _los_point_reached
	state[&"last_known_point_reached"] = _last_known_point_reached
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


func start() -> void:
	if show_search_points and not _search_point_one_label.is_inside_tree():
			get_tree().current_scene.add_child(_search_point_one_label)
			get_tree().current_scene.add_child(_search_point_two_label)

	npc.nav_agent.target_position = npc.broken_los_point
	npc.nav_agent.target_reached.connect(_on_reached_target)

	npc.move_speed = npc.walk_speed
	_los_point_reached = false
	_last_known_point_reached = false
	_head = npc.head_turner
	_head.active = true
	_head.target_node = searching_look_ahead.get_path()


func stop() -> void:
	npc.nav_agent.target_reached.disconnect(_on_reached_target)

	_first_wait_timer.stop()
	_second_wait_timer.stop()
	_reacquire_timer.stop()
	_stuck_timer.stop()

	searching_look_ahead_pivot.rotation_degrees.y = 0
	_head.target_node = NodePath("")

	if show_search_points:
		_search_point_one_label.visible = false
		_search_point_two_label.visible = false


func physics_process(delta: float) -> void:
	if show_search_points:
		_search_point_one_label.visible = true
		_search_point_one_label.global_position = npc.broken_los_point
		_search_point_two_label.visible = true
		_search_point_two_label.global_position = npc.last_known_target_point

	_sight_detection_check()
	if npc.nav_agent.is_target_reached():
		npc.stop_moving(delta)
	else:
		if _reacquire_timer.is_stopped():
			_turn_head(delta)
			npc.move_npc_to_next_position(delta)

		if not npc.nav_agent.is_target_reachable() and _stuck_timer.is_stopped():
			_stuck_timer.start()


func _sight_detection_check() -> void:
	if sight_detection.check_if_player_in_los():
		_stuck_timer.stop()
		if _reacquire_timer.is_stopped():
			_head.target_node = npc.search_target.head.get_path()
			target_spotted.emit()
			_reacquire_timer.start()
	else:
		_head.target_node = searching_look_ahead.get_path()
		_reacquire_timer.stop()


func _on_reached_target() -> void:
	if not _los_point_reached:
		_los_point_reached = true
		_first_wait_timer.start()
	elif not _last_known_point_reached:
		_last_known_point_reached = true
		_second_wait_timer.start()


func _search_next_point() -> void:
	npc.nav_agent.target_position = npc.last_known_target_point


func _turn_head(delta: float) -> void:
	if head_target_rotation_angle > 0:
		searching_look_ahead_pivot.rotate_y(deg_to_rad(180) * delta)
		if searching_look_ahead_pivot.rotation_degrees.y >= head_target_rotation_angle:
			head_target_rotation_angle *= -1
	else:
		searching_look_ahead_pivot.rotate_y(deg_to_rad(-180) * delta)
		if searching_look_ahead_pivot.rotation_degrees.y <= head_target_rotation_angle:
			head_target_rotation_angle *= -1


func _create_timer(wait_time: float, call_on_timeout: Callable) -> Timer:
	var timer := Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(call_on_timeout)
	add_child(timer)
	return timer


func _create_debug_label(text: String) -> Label3D:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.text = text
	return label

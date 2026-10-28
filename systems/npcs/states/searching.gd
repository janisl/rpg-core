extends NpcStateProcessor

@export var sight_detection: SightDetection
@export var searching_look_ahead_pivot: Node3D
@export var searching_look_ahead: Node3D

@export var reacquire_time := 0.5
@export var head_target_rotation_angle := 60.0
@export var reset_suspicion_when_search_ends := true
@export var wait_at_first_point := 5.0
@export var end_search_after_second_point := 3.0
@export var end_search_if_stuck_for := 10.0

@export var searching_sound: AudioStream
@export var end_search_sound: AudioStream
@export var i_see_you_sound: AudioStream

@export var show_search_points := false

var broken_los_point: Vector3
var last_known_player_point: Vector3

var player: Player:
	get:
		if not player:
			return get_tree().get_first_node_in_group("player")
		return player

var _search_point_one_label: Label3D
var _search_point_two_label: Label3D

var _los_point_reached := false
var _last_known_point_reached := false

var _reacquire_timer: Timer
var _first_wait_timer: Timer
var _second_wait_timer: Timer
var _stuck_timer: Timer

var _head: LookAtModifier3D


func _enter_tree() -> void:
	if show_search_points:
		_search_point_one_label = _create_debug_label("1")
		_search_point_two_label = _create_debug_label("2")

	_first_wait_timer = _create_timer(wait_at_first_point, _search_next_point)
	_second_wait_timer = _create_timer(end_search_after_second_point, _end_search)
	_reacquire_timer = _create_timer(reacquire_time, _start_chasing)
	_stuck_timer = _create_timer(end_search_if_stuck_for, _end_search)


func _on_searching_state_entered() -> void:
	_enter_state()
	if show_search_points and not _search_point_one_label.is_inside_tree():
			get_tree().current_scene.add_child(_search_point_one_label)
			get_tree().current_scene.add_child(_search_point_two_label)

	npc.nav_agent.target_position = broken_los_point
	npc.nav_agent.target_reached.connect(_on_reached_target)

	play_sound(searching_sound)
	state_chart.send_event("body_walk")
	npc.move_speed = npc.walk_speed
	_los_point_reached = false
	_last_known_point_reached = false
	_head = npc.head_turner
	_head.active = true
	_head.target_node = searching_look_ahead.get_path()


func _on_searching_state_exited() -> void:
	_exit_state()
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


func _on_searching_state_physics_processing(delta: float) -> void:
	if show_search_points:
		_search_point_one_label.visible = true
		_search_point_one_label.global_position = broken_los_point
		_search_point_two_label.visible = true
		_search_point_two_label.global_position = last_known_player_point

	_sight_detection_check()
	if npc.nav_agent.is_target_reached():
		npc.velocity.x = move_toward(npc.velocity.x, 0, delta * npc.move_speed)
		npc.velocity.z = move_toward(npc.velocity.z, 0, delta * npc.move_speed)
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
			_head.target_node = player.head.get_path()
			play_sound(i_see_you_sound)
			_reacquire_timer.start()
	else:
		_head.target_node = searching_look_ahead.get_path()
		_reacquire_timer.stop()


func _start_chasing() -> void:
	npc.attention_target = player
	state_chart.send_event("chase")


func _on_reached_target() -> void:
	if not _los_point_reached:
		_los_point_reached = true
		_first_wait_timer.start()
	elif not _last_known_point_reached:
		_last_known_point_reached = true
		_second_wait_timer.start()


func _search_next_point() -> void:
	npc.nav_agent.target_position = last_known_player_point


func _end_search() -> void:
	play_sound(end_search_sound)
	if reset_suspicion_when_search_ends:
		if npc.sight_detection:
			npc.sight_detection.reset()
	state_chart.send_event("idle")


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

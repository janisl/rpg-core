extends NpcStateProcessor

@export var wait_at_first_point := 5.0
@export var end_search_after_second_point := 3.0

@export var searching_sound: AudioStream
@export var end_search_sound: AudioStream

var broken_los_point: Vector3
var last_known_player_point: Vector3


var _los_point_reached := false
var _last_known_point_reached := false

var _first_wait_timer: Timer
var _second_wait_timer: Timer


func _enter_tree() -> void:
	_first_wait_timer = _create_timer(wait_at_first_point, _search_next_point)
	_second_wait_timer = _create_timer(end_search_after_second_point, _end_search)
func _on_searching_state_entered() -> void:
	_enter_state()

	npc.nav_agent.target_position = broken_los_point
	npc.nav_agent.target_reached.connect(_on_reached_target)

	play_sound(searching_sound)
	state_chart.send_event("body_walk")
	npc.move_speed = npc.walk_speed
	_los_point_reached = false
	_last_known_point_reached = false


func _on_searching_state_exited() -> void:
	_exit_state()
	npc.nav_agent.target_reached.disconnect(_on_reached_target)

	_first_wait_timer.stop()
	_second_wait_timer.stop()


func _on_searching_state_physics_processing(delta: float) -> void:
	if npc.nav_agent.is_target_reached():
		npc.velocity.x = move_toward(npc.velocity.x, 0, delta * npc.move_speed)
		npc.velocity.z = move_toward(npc.velocity.z, 0, delta * npc.move_speed)
	else:
			npc.move_npc_to_next_position(delta)


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
	state_chart.send_event("idle")


func _create_timer(wait_time: float, call_on_timeout: Callable) -> Timer:
	var timer := Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(call_on_timeout)
	add_child(timer)
	return timer

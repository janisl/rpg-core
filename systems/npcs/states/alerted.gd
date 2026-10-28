extends NpcStateProcessor

@export var alerted_sound: AudioStream
@export var must_have_been_the_wind_sound: AudioStream
@export var initial_shock_time := 1.5
@export var wait_time_once_reached := 5.0

var _shock_timer: Timer
var _return_to_patrol_timer: Timer
var _target: Vector3


func _enter_tree() -> void:
	_shock_timer = _create_timer(initial_shock_time, _start_moving)
	_return_to_patrol_timer = _create_timer(wait_time_once_reached, _return_to_patrol)


func _on_alerted_state_entered() -> void:
	_enter_state()
	_shock_timer.start()
	_target = npc.attention_target.global_position
	play_sound(alerted_sound)


func _on_alerted_state_exited() -> void:
	_exit_state()


func _on_alerted_state_physics_processing(delta: float) -> void:
	if not npc.attention_target:
		state_chart.send_event("idle")
		return

	if not _shock_timer.is_stopped() or not _return_to_patrol_timer.is_stopped():
		npc.face_direction(npc.attention_target.global_position)

	if npc.nav_agent.target_position == npc.attention_target.global_position and not npc.nav_agent.is_target_reached():
		npc.move_npc_to_next_position(delta)
	else:
		npc.velocity.x = move_toward(npc.velocity.x, 0, delta * npc.move_speed)
		npc.velocity.z = move_toward(npc.velocity.z, 0, delta * npc.move_speed)
		npc.move_and_slide()

	if (npc.nav_agent.is_target_reached() or not npc.nav_agent.is_target_reachable()) and _return_to_patrol_timer.is_stopped():
		_return_to_patrol_timer.start()


func _start_moving() -> void:
	npc.nav_agent.target_position = _target


func _return_to_patrol() -> void:
	state_chart.send_event("idle")
	play_sound(must_have_been_the_wind_sound)


func _create_timer(wait_time: float, call_on_timeout: Callable) -> Timer:
	var timer := Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(call_on_timeout)
	add_child(timer)
	return timer

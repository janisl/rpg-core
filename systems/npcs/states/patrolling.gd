extends NpcStateProcessor

enum TravelStatus { RUNNING, WAITING }

@export var patrol_point_wait_time := 3.0

var _current_travel_status: TravelStatus

var _patrol_wait_timer: Timer


func _enter_tree() -> void:
	_patrol_wait_timer = Timer.new()
	_patrol_wait_timer.wait_time = patrol_point_wait_time
	_patrol_wait_timer.one_shot = true
	_patrol_wait_timer.timeout.connect(_resume_patrolling)
	add_child(_patrol_wait_timer)


func _on_patrolling_state_entered() -> void:
	assert(npc.patrol_path, "Entered patrol state without patrol path")

	_enter_state()
	state_chart.send_event("ubody_neutral")

	_resume_patrolling()


func _on_patrolling_state_exited() -> void:
	_exit_state()


func _on_patrolling_state_physics_processing(delta: float) -> void:
	match _current_travel_status:
		TravelStatus.WAITING:
			npc.velocity.x = move_toward(npc.velocity.x, 0, delta * npc.move_speed)
			npc.velocity.z = move_toward(npc.velocity.z, 0, delta * npc.move_speed)
			npc.move_and_slide()
			return
		TravelStatus.RUNNING:
			_running(delta)


func _running(delta: float) -> void:
	if not npc.nav_agent.is_target_reachable():
		npc.nav_agent.target_position = npc.patrol_path.starting_patrol_point.global_position

	if npc.nav_agent.is_navigation_finished():
		_wait_at_patrol_point()
		return

	npc.move_npc_to_next_position(delta)


func _wait_at_patrol_point() -> void:
	_patrol_wait_timer.start()
	_current_travel_status = TravelStatus.WAITING


func _resume_patrolling() -> void:
	npc.nav_agent.target_position = _set_next_patrol_point_destination()
	_current_travel_status = TravelStatus.RUNNING


func _set_next_patrol_point_destination() -> Vector3:
	return npc.patrol_path.target_next_patrol_point().global_position

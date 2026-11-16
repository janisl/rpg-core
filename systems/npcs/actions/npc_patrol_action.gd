class_name NpcPatrolAction
extends Node

enum TravelStatus { RUNNING, WAITING }

@export var patrol_point_wait_time := 3.0

var _current_travel_status: TravelStatus

var _patrol_wait_timer: Timer

@onready var npc: Npc = $".."


func _enter_tree() -> void:
	_patrol_wait_timer = Timer.new()
	_patrol_wait_timer.wait_time = patrol_point_wait_time
	_patrol_wait_timer.one_shot = true
	_patrol_wait_timer.timeout.connect(_resume_patrolling)
	add_child(_patrol_wait_timer)


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"current_travel_status"] = _current_travel_status
	SaveUtils.save_timer(state, &"patrol_wait_timer", _patrol_wait_timer)
	return state


func load_state(state: Dictionary) -> void:
	_current_travel_status = state.get(&"current_travel_status", TravelStatus.RUNNING)
	SaveUtils.load_timer(state, &"patrol_wait_timer", _patrol_wait_timer)


func start() -> void:
	assert(npc.patrol_path, "Entered patrol state without patrol path")
	npc.set_upper_body_neutral()
	_resume_patrolling()


func physics_process(delta: float) -> void:
	match _current_travel_status:
		TravelStatus.WAITING:
			npc.stop_moving(delta)
		TravelStatus.RUNNING:
			_running(delta)


func check_for_bumping_into_hostile() -> Actor:
	for i in npc.get_slide_collision_count():
		var collision := npc.get_slide_collision(i)
		if collision.get_collider() is Player and npc.response_to_player == "Hostile":
			return collision.get_collider()
	return null


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
	npc.nav_agent.target_position = npc.patrol_path.target_next_patrol_point().global_position
	_current_travel_status = TravelStatus.RUNNING

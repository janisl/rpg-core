class_name NpcPatrolAction
extends Node

## Walks the NPC along its patrol path, waiting at each patrol point.
## Holds no transition logic, so it can be driven by a state or a behaviour tree leaf.

enum TravelStatus { RUNNING, WAITING }

var npc: Npc
var patrol_point_wait_time := 3.0

var _current_travel_status: TravelStatus

var _patrol_wait_timer: Timer


func _init(p_npc: Npc, p_patrol_point_wait_time: float) -> void:
	npc = p_npc
	patrol_point_wait_time = p_patrol_point_wait_time


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
	assert(npc.has_patrol_path(), "Started patrolling without patrol path")
	_resume_patrolling()


func physics_process(delta: float) -> void:
	match _current_travel_status:
		TravelStatus.WAITING:
			npc.stop_moving(delta)
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
	npc.nav_agent.target_position = npc.patrol_path.target_next_patrol_point().global_position
	_current_travel_status = TravelStatus.RUNNING

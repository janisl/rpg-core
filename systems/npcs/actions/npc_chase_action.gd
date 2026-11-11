class_name NpcChaseAction
extends Node

## Runs after the chase target, waits when it is unreachable and tracks line of sight.
## Holds no transition logic, so it can be driven by a state or a behaviour tree leaf.

## Emitted when line of sight to the target breaks, with the target's position at that moment.
signal line_of_sight_broken(point: Vector3)
## Emitted when the target is lost: out of sight for too long, unreachable for too long, or dead.
signal target_lost

enum Outcome { RUNNING, CAUGHT, LOST }

enum ChaseStatus { CHASING, CAUGHT, WAITING, LOST }

var npc: Npc
var target_melee_distance := 1.5
var target_ranged_distance_offset := 1.0
var giveup_chase_time := 5.0
var wait_after_broken_los_time := 3.0
var face_target_while_waiting := true
var collision_mask: int

var chase_target: Node3D

var _chase_wait_timer: Timer
var _los_broken_timer: Timer
var _current_chase_status: ChaseStatus
var _can_see_player := false


func _init(p_npc: Npc) -> void:
	npc = p_npc


func _enter_tree() -> void:
	_chase_wait_timer = Timer.new()
	_chase_wait_timer.wait_time = giveup_chase_time
	_chase_wait_timer.one_shot = true
	_chase_wait_timer.timeout.connect(_stop_chasing)
	add_child(_chase_wait_timer)

	_los_broken_timer = Timer.new()
	_los_broken_timer.wait_time = wait_after_broken_los_time
	_los_broken_timer.one_shot = true
	_los_broken_timer.timeout.connect(target_lost.emit)
	add_child(_los_broken_timer)


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_timer(state, &"chase_wait_timer", _chase_wait_timer)
	SaveUtils.save_timer(state, &"los_broken_timer", _los_broken_timer)
	state[&"current_chase_status"] = _current_chase_status
	SaveUtils.save_ref(state, &"chase_target", chase_target)
	state[&"can_see_player"] = _can_see_player
	return state


func load_state(state: Dictionary) -> void:
	SaveUtils.load_timer(state, &"chase_wait_timer", _chase_wait_timer)
	SaveUtils.load_timer(state, &"los_broken_timer", _los_broken_timer)
	_current_chase_status = state.get(&"current_chase_status", ChaseStatus.CHASING)
	chase_target = SaveUtils.load_ref(state, &"chase_target")
	_can_see_player = state.get(&"can_see_player", false)


func start(target: Node3D) -> void:
	chase_target = target
	npc.move_speed = npc.sprint_speed
	_current_chase_status = ChaseStatus.CHASING
	npc.head_turner.target_node = chase_target.get_path()


func stop() -> void:
	chase_target = null


func physics_process(delta: float) -> Outcome:
	# When loading a game during a chase, the attention target needs to be reacquired
	if not chase_target and npc.attention_target:
		chase_target = npc.attention_target

	_can_see_player = _check_los_to_player()
	if _can_see_player:
		npc.head_turner.active = true
		_los_broken_timer.stop()
	else:
		npc.head_turner.active = false
		if _los_broken_timer.is_stopped() and _chase_wait_timer.is_stopped():
			line_of_sight_broken.emit(chase_target.global_position)
			_los_broken_timer.start()

	if not chase_target or not (chase_target as Player).health_attribute.is_alive:
		_stop_chasing()

	if npc.is_dead():
		_current_chase_status = ChaseStatus.LOST

	match _current_chase_status:
		ChaseStatus.CHASING:
			_running(delta)

		ChaseStatus.CAUGHT:
			return Outcome.CAUGHT

		ChaseStatus.WAITING:
			npc.stop_moving(delta)

			if face_target_while_waiting:
				npc.face_direction(chase_target.global_position)

			npc.nav_agent.target_position = chase_target.global_position
			if npc.nav_agent.is_target_reachable() or _can_see_player:
				_chase_wait_timer.stop()
				_current_chase_status = ChaseStatus.CHASING

		ChaseStatus.LOST:
			target_lost.emit()
			return Outcome.LOST

	return Outcome.RUNNING


func _check_los_to_player() -> bool:
	var space_state := npc.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(npc.head.global_position, chase_target.global_position, collision_mask)
	query.exclude = [npc.get_rid()]
	var result := space_state.intersect_ray(query)
	if result:
		return result.collider is Player
	return false


func _running(delta: float) -> void:
	npc.nav_agent.target_position = chase_target.global_position
	var distance_to_target := npc.global_position.distance_to(chase_target.global_position)

	if _can_see_player:
		var ranged_distance := _get_wieldable_range()
		if ranged_distance > 0 and distance_to_target <= ranged_distance - target_ranged_distance_offset:
			_current_chase_status = ChaseStatus.CAUGHT
		elif distance_to_target <= target_melee_distance:
			_current_chase_status = ChaseStatus.CAUGHT

	if not npc.nav_agent.is_target_reachable():
		_start_waiting()

	npc.move_npc_to_next_position(delta)


func _get_wieldable_range() -> float:
	if npc.is_using_weapon():
		return npc.get_weapon_range()
	return 0


func _start_waiting() -> void:
	_current_chase_status = ChaseStatus.WAITING
	_chase_wait_timer.start()


func _stop_chasing() -> void:
	npc.move_speed = npc.walk_speed
	_current_chase_status = ChaseStatus.LOST

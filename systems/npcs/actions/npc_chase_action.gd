class_name NpcChaseAction
extends Node

enum ChaseStatus { CHASING, CAUGHT, WAITING, LOST }

@export var target_melee_distance := 1.5
@export var target_ranged_distance_offset := 1.0
@export var giveup_chase_time := 5.0
@export var wait_after_broken_los_time := 3.0
@export var face_target_while_waiting := true

var _chase_wait_timer: Timer
var _los_broken_timer: Timer
var _current_chase_status: ChaseStatus

@onready var npc: Npc = $".."


func _enter_tree() -> void:
	_chase_wait_timer = Timer.new()
	_chase_wait_timer.wait_time = giveup_chase_time
	_chase_wait_timer.one_shot = true
	_chase_wait_timer.timeout.connect(_stop_chasing)
	add_child(_chase_wait_timer)

	_los_broken_timer = Timer.new()
	_los_broken_timer.wait_time = wait_after_broken_los_time
	_los_broken_timer.one_shot = true
	_los_broken_timer.timeout.connect(_target_los_lost)
	add_child(_los_broken_timer)


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_timer(state, &"chase_wait_timer", _chase_wait_timer)
	SaveUtils.save_timer(state, &"los_broken_timer", _los_broken_timer)
	state[&"current_chase_status"] = _current_chase_status
	return state


func load_state(state: Dictionary) -> void:
	SaveUtils.load_timer(state, &"chase_wait_timer", _chase_wait_timer)
	SaveUtils.load_timer(state, &"los_broken_timer", _los_broken_timer)
	_current_chase_status = state.get(&"current_chase_status", ChaseStatus.CHASING)


func start() -> void:
	npc.set_running_speed()
	npc.set_upper_body_raised_weapon()
	_current_chase_status = ChaseStatus.CHASING
	npc.head_turner.target_node = npc.chase_target.get_path()


func physics_process(delta: float) -> ChaseStatus:
	if not npc.has_valid_chase_target():
		return ChaseStatus.LOST

	var can_see_target := npc.sight_detection.check_if_chase_target_in_los()
	if can_see_target:
		npc.head_turner.active = true
		_los_broken_timer.stop()
	else:
		npc.head_turner.active = false
		if _los_broken_timer.is_stopped() and _chase_wait_timer.is_stopped():
			npc.broken_los_point = npc.chase_target.global_position
			_los_broken_timer.start()

	if npc.is_dead():
		_current_chase_status = ChaseStatus.LOST

	match _current_chase_status:
		ChaseStatus.CHASING:
			_running(delta, can_see_target)

		ChaseStatus.WAITING:
			npc.stop_moving(delta)

			if face_target_while_waiting:
				npc.face_direction(npc.chase_target.global_position)

			npc.nav_agent.target_position = npc.chase_target.global_position
			if npc.nav_agent.is_target_reachable() or can_see_target:
				_chase_wait_timer.stop()
				_current_chase_status = ChaseStatus.CHASING

		ChaseStatus.LOST:
			npc.remember_lost_target()

	return _current_chase_status


func _running(delta: float, can_see_target: bool) -> void:
	npc.nav_agent.target_position = npc.chase_target.global_position
	var distance_to_target := npc.global_position.distance_to(npc.chase_target.global_position)

	if can_see_target:
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
	_current_chase_status = ChaseStatus.LOST


func _target_los_lost() -> void:
	_current_chase_status = ChaseStatus.LOST

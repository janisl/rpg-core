extends NpcStateProcessor

enum ChaseStatus { CHASING, CAUGHT, WAITING, LOST }

@export var target_melee_distance := 1.5
@export var target_ranged_distance_offset := 1.0
@export var action_when_caught := "attack"
@export var start_chase_sound: AudioStream
@export var giveup_chase_time := 5.0
@export var wait_after_broken_los_time := 3.0
@export var face_target_while_waiting := true
@export var searching_state: NpcStateProcessor

@export_flags_3d_physics var collision_mask := (
	PhysicsLayers.WORLD_MASK |
	PhysicsLayers.PLAYER_MASK |
	PhysicsLayers.NPCS_MASK |
	PhysicsLayers.DYNAMIC_OBJECTS_MASK
)

var _chase_wait_timer: Timer
var _los_broken_timer: Timer
var _current_chase_status: ChaseStatus
var _chase_target: Node3D
var _can_see_player := false


func _enter_tree() -> void:
	_chase_wait_timer = Timer.new()
	_chase_wait_timer.wait_time = giveup_chase_time
	_chase_wait_timer.one_shot = true
	_chase_wait_timer.timeout.connect(_stop_chasing)
	add_child(_chase_wait_timer)

	_los_broken_timer = Timer.new()
	_los_broken_timer.wait_time = wait_after_broken_los_time
	_los_broken_timer.one_shot = true
	_los_broken_timer.timeout.connect(_start_searching)
	add_child(_los_broken_timer)


func _on_chasing_state_entered() -> void:
	_enter_state()
	if npc.attention_target is Player:
		_chase_target = npc.attention_target

	if not _chase_target or npc.response_to_player == "Neutral":
		state_chart.send_event("search")
		state_chart.send_event("body_walk")
		return

	if npc.previous_behaviour != Npc.BehaviourState.Attacking:
		play_sound(start_chase_sound)
	state_chart.send_event("body_run")
	state_chart.send_event("ubody_raise_weapon")
	npc.move_speed = npc.sprint_speed
	_current_chase_status = ChaseStatus.CHASING
	npc.head_turner.target_node = _chase_target.get_path()


func _on_chasing_state_exited() -> void:
	_exit_state()
	_chase_target = null


func _on_chasing_state_physics_processing(delta: float) -> void:
	# When loading a game during a chase, the attention target needs to be reacquired
	if not _chase_target and npc.attention_target:
		_chase_target = npc.attention_target

	_can_see_player = _check_los_to_player()
	if _can_see_player:
		npc.head_turner.active = true
		_los_broken_timer.stop()
	else:
		npc.head_turner.active = false
		if _los_broken_timer.is_stopped() and _chase_wait_timer.is_stopped():
			searching_state.broken_los_point = _chase_target.global_position
			_los_broken_timer.start()

	if not _chase_target or not (_chase_target as Player).health_attribute.is_alive:
		_stop_chasing()

	if npc.is_dead():
		_npc_has_died()

	match _current_chase_status:
		ChaseStatus.CHASING:
			_running(delta)
			return

		ChaseStatus.CAUGHT:
			state_chart.send_event(action_when_caught)
			return

		ChaseStatus.WAITING:
			npc.velocity.x = move_toward(npc.velocity.x, 0, delta * npc.move_speed)
			npc.velocity.z = move_toward(npc.velocity.z, 0, delta * npc.move_speed)
			npc.move_and_slide()

			if face_target_while_waiting:
				npc.face_direction(_chase_target.global_position)

			npc.nav_agent.target_position = _chase_target.global_position
			if npc.nav_agent.is_target_reachable() or _can_see_player:
				_chase_wait_timer.stop()
				_current_chase_status = ChaseStatus.CHASING
			return

		ChaseStatus.LOST:
			_start_searching()
			return


func _check_los_to_player() -> bool:
	var space_state := npc.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(npc.head.global_position, _chase_target.global_position, collision_mask)
	query.exclude = [npc.get_rid()]
	var result := space_state.intersect_ray(query)
	if result:
		return result.collider is Player
	return false


func _running(delta: float) -> void:
	npc.nav_agent.target_position = _chase_target.global_position
	var distance_to_target := npc.global_position.distance_to(_chase_target.global_position)

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


func _npc_has_died() -> void:
	_current_chase_status = ChaseStatus.LOST


func _start_searching() -> void:
	searching_state.last_known_player_point = npc.last_reachable_path
	state_chart.send_event("search")
	state_chart.send_event("body_walk")

extends NpcStateProcessor

enum ChaseStatus { CHASING, CAUGHT }

@export var target_melee_distance := 1.5
@export var target_ranged_distance_offset := 1.0
@export var action_when_caught := "attack"
@export var start_chase_sound: AudioStream
@export_flags_3d_physics var collision_mask := 1

var _current_chase_status: ChaseStatus
var _chase_target: Node3D
var _can_see_player := false


func _on_chasing_state_entered() -> void:
	_enter_state()
	if npc.attention_target is Player:
		_chase_target = npc.attention_target

	if !_chase_target or npc.response_to_player == "Neutral":
		state_chart.send_event("onIdle")
		state_chart.send_event("body_walk")
		return

	if not npc.previous_behaviour == Npc.BehaviourState.Attacking:
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
	_can_see_player = _check_los_to_player()

	match _current_chase_status:
		ChaseStatus.CHASING:
			_running(delta)
			return

		ChaseStatus.CAUGHT:
			state_chart.send_event(action_when_caught)
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

	npc.move_npc_to_next_position(delta)


func _get_wieldable_range() -> float:
	if npc.is_using_weapon():
		return npc.get_weapon_range()
	return 0

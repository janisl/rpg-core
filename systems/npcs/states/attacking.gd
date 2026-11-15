extends NpcStateProcessor

@export var state_after_attack: String
@export var can_attack_while_moving := false

@export_group("Melee attack properties")
@export var attack_impact_zone: ImpactZone
@export var attack_sound: AudioStream
@export var attack_duration := 1.0

var _count_down := 0.0


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"count_down"] = _count_down
	state[&"attack_impact_zone_enabled"] = attack_impact_zone.monitoring
	return state


func load_state(state: Dictionary) -> void:
	_count_down = state.get(&"count_down", 0.0)
	attack_impact_zone.monitoring = state.get(&"attack_impact_zone_enabled", false)


func _on_attacking_state_entered() -> void:
	_enter_state()
	if not npc.chase_target:
		state_chart.send_event(state_after_attack)
	else:
		_count_down = attack_duration
		if _attack_while_moving():
			_attempt_attack()


func _on_attacking_state_exited() -> void:
	_exit_state()
	attack_impact_zone.set_collision(false)


func _on_attacking_state_physics_processing(delta: float) -> void:
	npc.stop_moving(delta)
	if npc.chase_target:
		npc.face_direction(npc.chase_target.global_position)

	if _count_down <= 0 and _attack_while_moving():
		_attempt_attack()
		state_chart.send_event(state_after_attack)
	else:
		_count_down -= delta


func _attack_while_moving() -> bool:
	if can_attack_while_moving or not npc.is_using_weapon():
		return true
	return npc.velocity.length_squared() == 0


func _attempt_attack() -> void:
	if not npc.is_using_weapon():
		_count_down = attack_duration
		state_chart.send_event("ubody_attack")
		_punch_attack()
	else:
		_count_down = attack_duration
		npc.sight_detection.check_if_player_in_los()
		npc.do_weapon_attack()


func _punch_attack() -> void:
	AudioManager.play_sound_3d(attack_sound, npc.global_position)

	attack_impact_zone.set_collision(true)

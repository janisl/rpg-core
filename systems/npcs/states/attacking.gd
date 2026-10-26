extends NpcStateProcessor

@export var state_after_attack: String
@export var can_attack_while_moving := false

@export_group("Melee attack properties")
@export var attack_impact_zone: ImpactZone
@export var attack_sound: AudioStream
@export var attack_duration := 1.0
@export var melee_range := 1.5

var _target: Node3D
var _count_down := 0.0


func _on_attacking_state_entered() -> void:
	_enter_state()
	_target = npc.attention_target
	if !_target:
		state_chart.send_event(state_after_attack)
	else:
		_count_down = attack_duration
		if _attack_while_moving():
			_attempt_attack()


func _on_attacking_state_exited() -> void:
	_exit_state()
	attack_impact_zone.set_collision(false)


func _on_attacking_state_physics_processing(delta: float) -> void:
	npc.velocity.x = move_toward(npc.velocity.x, 0, delta * npc.move_speed)
	npc.velocity.z = move_toward(npc.velocity.z, 0, delta * npc.move_speed)
	npc.face_direction(_target.global_position)
	npc.move_and_slide()

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
		if npc.global_position.distance_to(_target.global_position) <= melee_range:
			_punch_attack()
	else:
		_count_down = attack_duration
		npc.sight_detection.check_if_player_in_los()
		npc.do_weapon_attack()


func _punch_attack() -> void:
	AudioManager.play_sound_3d(attack_sound, npc.global_position)

	attack_impact_zone.set_collision(true)

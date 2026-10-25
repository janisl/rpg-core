extends NpcStateProcessor

@export var state_after_attack : String

@export_group("Melee attack properties")
@export var attack_impact_zone: ImpactZone
@export var attack_sound : AudioStream
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
	return true


func _attempt_attack():
	_count_down = attack_duration
	state_chart.send_event("ubody_attack")
	if npc.global_position.distance_to(_target.global_position) <= melee_range:
		_punch_attack()


func _punch_attack():
	AudioManager.play_sound_3d(attack_sound, npc.global_position)

	attack_impact_zone.set_collision(true)

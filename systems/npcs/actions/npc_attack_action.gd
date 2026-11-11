class_name NpcAttackAction
extends RefCounted

## Stands still facing the target and attacks it, with a punch or the wielded weapon.
## Holds no transition logic, so it can be driven by a state or a behaviour tree leaf.

var npc: Npc
var can_attack_while_moving := false
var attack_impact_zone: ImpactZone
var attack_sound: AudioStream
var attack_duration := 1.0
var melee_range := 1.5

var _target: Node3D
var _count_down := 0.0


func _init(p_npc: Npc) -> void:
	npc = p_npc


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_ref(state, &"target", _target)
	state[&"count_down"] = _count_down
	state[&"attack_impact_zone_enabled"] = attack_impact_zone.monitoring
	return state


func load_state(state: Dictionary) -> void:
	_target = SaveUtils.load_ref(state, &"target")
	_count_down = state.get(&"count_down", 0.0)
	attack_impact_zone.monitoring = state.get(&"attack_impact_zone_enabled", false)


func start(target: Node3D) -> void:
	_target = target
	_count_down = attack_duration
	if _can_attack_now():
		_attempt_attack()


func stop() -> void:
	attack_impact_zone.set_collision(false)


## Returns true once the attack is over.
func physics_process(delta: float) -> bool:
	npc.stop_moving(delta)
	npc.face_direction(_target.global_position)

	if _count_down <= 0 and _can_attack_now():
		_attempt_attack()
		return true

	_count_down -= delta
	return false


func _can_attack_now() -> bool:
	if can_attack_while_moving or not npc.is_using_weapon():
		return true
	return npc.velocity.length_squared() == 0


func _attempt_attack() -> void:
	_count_down = attack_duration
	if not npc.is_using_weapon():
		npc.set_upper_body_attack()
		if npc.global_position.distance_to(_target.global_position) <= melee_range:
			_punch_attack()
	else:
		npc.sight_detection.check_if_player_in_los()
		npc.do_weapon_attack()


func _punch_attack() -> void:
	AudioManager.play_sound_3d(attack_sound, npc.global_position)
	attack_impact_zone.set_collision(true)

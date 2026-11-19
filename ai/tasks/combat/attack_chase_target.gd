@tool
extends NpcBTAction
## Stands and attacks the chase target once: a punch without a weapon, a weapon
## attack otherwise. SUCCESS after [member attack_duration].

@export var attack_duration := 1.0
@export var can_attack_while_moving := false
@export var impact_zone_path: NodePath = ^"Rig/GeneralSkeleton/HandAttachment/ImpactZone"

var _impact_zone: ImpactZone
var _time_left := 0.0
var _did_attack := false


func _setup() -> void:
	_impact_zone = agent.get_node(impact_zone_path)


func _start() -> void:
	_time_left = attack_duration
	_did_attack = false


func _update(delta: float) -> Status:
	agent.stop_moving(delta)
	if agent.chase_target:
		agent.face_direction(agent.chase_target.global_position)

	if not _did_attack and _can_attack_now():
		_attack()
		_did_attack = true

	if _time_left <= 0.0:
		return SUCCESS
	_time_left -= delta
	return RUNNING


func _end() -> void:
	_impact_zone.set_collision(false)


func _can_attack_now() -> bool:
	if can_attack_while_moving or not agent.is_using_weapon():
		return true
	return agent.velocity.length_squared() == 0


func _attack() -> void:
	_time_left = attack_duration
	if agent.is_using_weapon():
		agent.do_weapon_attack()
	else:
		agent.set_upper_body_attack()
		AudioManager.play_sound_3d(agent.sounds.attack_sound, agent.global_position)
		_impact_zone.set_collision(true)


func _save_state() -> Dictionary:
	return {
		&"time_left": _time_left,
		&"did_attack": _did_attack,
		&"impact_zone_enabled": _impact_zone.monitoring,
	}


func _load_state(state: Dictionary) -> void:
	_time_left = state.get(&"time_left", 0.0)
	_did_attack = state.get(&"did_attack", false)
	_impact_zone.monitoring = state.get(&"impact_zone_enabled", false)

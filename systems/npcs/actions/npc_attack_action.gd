class_name NpcAttackAction
extends Node

@export var can_attack_while_moving := false

@export_group("Melee attack properties")
@export var attack_impact_zone: ImpactZone
@export var attack_duration := 1.0

var _count_down := 0.0
var _did_attack: bool

@onready var npc: Npc = $".."


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"count_down"] = _count_down
	state[&"did_attack"] = _did_attack
	state[&"attack_impact_zone_enabled"] = attack_impact_zone.monitoring
	return state


func load_state(state: Dictionary) -> void:
	_count_down = state.get(&"count_down", 0.0)
	_did_attack = state.get(&"did_attack", false)
	attack_impact_zone.monitoring = state.get(&"attack_impact_zone_enabled", false)


func start() -> void:
	_count_down = attack_duration
	_did_attack = false


func stop() -> void:
	attack_impact_zone.set_collision(false)


func physics_process(delta: float) -> bool:
	npc.stop_moving(delta)
	if npc.chase_target:
		npc.face_direction(npc.chase_target.global_position)

	if not _did_attack and _can_attack_now():
		_attempt_attack()
		_did_attack = true

	if _count_down <= 0:
		return true
	else:
		_count_down -= delta
		return false


func _can_attack_now() -> bool:
	if can_attack_while_moving or not npc.is_using_weapon():
		return true
	return npc.velocity.length_squared() == 0


func _attempt_attack() -> void:
	if not npc.is_using_weapon():
		_count_down = attack_duration
		npc.state_chart.send_event("ubody_attack")
		_punch_attack()
	else:
		_count_down = attack_duration
		npc.sight_detection.check_if_player_in_los()
		npc.do_weapon_attack()


func _punch_attack() -> void:
	AudioManager.play_sound_3d(npc.sounds.attack_sound, npc.global_position)

	attack_impact_zone.set_collision(true)

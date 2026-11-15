class_name NpcAttackAction
extends Node

@export var can_attack_while_moving := false

@export_group("Melee attack properties")
@export var attack_impact_zone: ImpactZone
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

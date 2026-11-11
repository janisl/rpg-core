@tool
extends NpcActionLeaf

## Succeeds after one attack, fails when there is nothing to attack.

@export var can_attack_while_moving := false

@export_group("Melee attack properties")
@export var attack_impact_zone: ImpactZone
@export var attack_sound: AudioStream
@export var attack_duration := 1.0
@export var melee_range := 1.5

var _attack_action: NpcAttackAction


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_attack_action = NpcAttackAction.new(npc)
	_attack_action.can_attack_while_moving = can_attack_while_moving
	_attack_action.attack_impact_zone = attack_impact_zone
	_attack_action.attack_sound = attack_sound
	_attack_action.attack_duration = attack_duration
	_attack_action.melee_range = melee_range


func _start() -> void:
	if npc.has_attention_target():
		_attack_action.start(npc.attention_target)


func _stop() -> void:
	_attack_action.stop()


func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if not npc.has_attention_target():
		return FAILURE

	if _attack_action.physics_process(get_physics_process_delta_time()):
		return SUCCESS

	return RUNNING

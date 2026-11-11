extends NpcStateProcessor

@export var state_after_attack: String
@export var can_attack_while_moving := false

@export_group("Melee attack properties")
@export var attack_impact_zone: ImpactZone
@export var attack_sound: AudioStream
@export var attack_duration := 1.0
@export var melee_range := 1.5

var _attack_action: NpcAttackAction


func _enter_tree() -> void:
	_attack_action = NpcAttackAction.new(npc)
	_attack_action.can_attack_while_moving = can_attack_while_moving
	_attack_action.attack_impact_zone = attack_impact_zone
	_attack_action.attack_sound = attack_sound
	_attack_action.attack_duration = attack_duration
	_attack_action.melee_range = melee_range


func save_state() -> Dictionary:
	return _attack_action.save_state()


func load_state(state: Dictionary) -> void:
	_attack_action.load_state(state)


func _on_attacking_state_entered() -> void:
	_enter_state()
	if not npc.has_attention_target():
		state_chart.send_event(state_after_attack)
	else:
		_attack_action.start(npc.attention_target)


func _on_attacking_state_exited() -> void:
	_exit_state()
	_attack_action.stop()


func _on_attacking_state_physics_processing(delta: float) -> void:
	if _attack_action.physics_process(delta):
		state_chart.send_event(state_after_attack)

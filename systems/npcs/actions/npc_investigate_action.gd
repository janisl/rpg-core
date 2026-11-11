class_name NpcInvestigateAction
extends RefCounted

## Walks the NPC to its current attention point.
## Holds no transition logic, so it can be driven by a state or a behaviour tree leaf.

var npc: Npc

var _attention_spot: Vector3


func _init(p_npc: Npc) -> void:
	npc = p_npc


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"attention_spot"] = _attention_spot
	return state


func load_state(state: Dictionary) -> void:
	_attention_spot = state.get(&"attention_spot", Vector3.ZERO)


func start() -> void:
	if npc.attention_target is AttentionPoint:
		_attention_spot = npc.attention_target.global_position
		npc.nav_agent.target_position = _attention_spot


func physics_process(delta: float) -> void:
	npc.move_npc_to_next_position(delta)

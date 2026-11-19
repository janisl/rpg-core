@tool
extends NpcBTAction
## Stores the position of the active attention point (sight first). FAILURE if
## neither is active.

@export var output_var: StringName = &"attention_target"


func _generate_name() -> String:
	return "PickAttentionPoint ➜ %s" % LimboUtility.decorate_var(output_var)


func _update(_delta: float) -> Status:
	var point: AttentionPoint
	if agent.sight_attention_point.is_active:
		point = agent.sight_attention_point
	elif agent.hearing_attention_point.is_active:
		point = agent.hearing_attention_point
	else:
		return FAILURE

	blackboard.set_var(output_var, point.global_position)
	return SUCCESS

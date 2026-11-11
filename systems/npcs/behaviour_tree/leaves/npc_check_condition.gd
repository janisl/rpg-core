@tool
class_name NpcCheckCondition
extends ConditionLeaf

## Succeeds when the given method on the NPC returns true.

@export var method: StringName
@export var invert := false


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var result: bool = actor.call(method)
	return SUCCESS if result != invert else FAILURE

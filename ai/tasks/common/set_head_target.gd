@tool
extends NpcBTAction
## Points the head turner at something and activates it.

enum Target { NONE, CHASE_TARGET_HEAD, NODE, CHASE_TARGET }

@export var target := Target.NONE
## Path relative to the agent, used with [constant NODE].
@export var node_path: NodePath


func _generate_name() -> String:
	var text := "SetHeadTarget %s" % Target.keys()[target].capitalize()
	if target == Target.NODE:
		text += " %s" % node_path
	return text


func _update(_delta: float) -> Status:
	var head: LookAtModifier3D = agent.head_turner
	match target:
		Target.NONE:
			head.target_node = NodePath("")
		Target.CHASE_TARGET_HEAD:
			if not agent.chase_target:
				return FAILURE
			head.target_node = agent.chase_target.head.get_path()
			head.active = true
		Target.CHASE_TARGET:
			if not agent.chase_target:
				return FAILURE
			head.target_node = agent.chase_target.get_path()
		Target.NODE:
			head.target_node = agent.get_node(node_path).get_path()
			head.active = true
	return SUCCESS

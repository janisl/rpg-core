@tool
extends NpcBTAction
## Navigates to a position. SUCCESS when reached, FAILURE when unreachable.

## Blackboard variable with the Vector3 position to go to.
@export var target_var: StringName = &"target_position"


func _generate_name() -> String:
	return "MoveTo %s" % LimboUtility.decorate_var(target_var)


func _start() -> void:
	agent.nav_agent.target_position = blackboard.get_var(target_var, agent.global_position)


func _resume() -> void:
	_start()


func _update(delta: float) -> Status:
	agent.move_npc_to_next_position(delta)
	if agent.nav_agent.is_target_reached():
		return SUCCESS
	if not agent.nav_agent.is_target_reachable():
		return FAILURE
	return RUNNING

@tool
extends NpcBTAction
## Condition: there's no path to the chase target and it isn't visible.


func _update(_delta: float) -> Status:
	agent.nav_agent.target_position = agent.chase_target.global_position
	agent.nav_agent.get_next_path_position()
	if agent.nav_agent.is_target_reachable() or agent.sight_detection.check_if_chase_target_in_los():
		return FAILURE
	return SUCCESS

@tool
extends NpcBTAction
## Starts a search: copies the points where the target was lost from the NPC
## onto the blackboard and resets search progress.

# TODO: Drop once chasing writes the points to the blackboard itself.


func _update(_delta: float) -> Status:
	blackboard.set_var(&"search_point_1", agent.broken_los_point)
	blackboard.set_var(&"search_point_2", agent.last_known_target_point)
	blackboard.set_var(&"search_stage", 0)
	return SUCCESS

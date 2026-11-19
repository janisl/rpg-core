@tool
extends NpcBTAction
## Stands still facing the chase target. Never finishes.


func _update(delta: float) -> Status:
	agent.stop_moving(delta)
	agent.face_direction(agent.chase_target.global_position)
	return RUNNING

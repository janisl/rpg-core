@tool
extends NpcBTAction
## Stands in place indefinitely, optionally facing a position. Never finishes;
## use it as the last step of a branch ended by something else.

## Blackboard variable with a Vector3 position to face. Empty to not turn.
@export var face_var: StringName


func _generate_name() -> String:
	if face_var:
		return "Stand facing %s" % LimboUtility.decorate_var(face_var)
	return "Stand"


func _update(delta: float) -> Status:
	agent.stop_moving(delta)
	if face_var:
		agent.face_direction(blackboard.get_var(face_var, agent.global_position))
	return RUNNING

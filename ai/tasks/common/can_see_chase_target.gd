@tool
extends NpcBTAction
## Checks line of sight to the chase target. With [member keep_running], stays
## RUNNING while it's visible and fails once it's lost, for use in a parallel.

@export var keep_running := false


func _generate_name() -> String:
	return "CanSeeChaseTarget" + (" (while)" if keep_running else "")


func _update(_delta: float) -> Status:
	if not agent.has_valid_chase_target() or not agent.sight_detection.check_if_chase_target_in_los():
		return FAILURE
	return RUNNING if keep_running else SUCCESS

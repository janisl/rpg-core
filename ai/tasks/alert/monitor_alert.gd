@tool
extends NpcBTAction
## Runs alongside the alerted behaviour. Builds up suspicion and switches to
## investigating once suspicious. FAILURE when attention is lost.


func _update(delta: float) -> Status:
	if not agent.has_attention():
		agent.end_alert()
		return FAILURE

	agent.sight_detection.update_suspicion(delta, false)
	if agent.sight_detection.is_suspicious_of_target():
		agent.set_sight_target(agent.sight_detection.detected_target.global_position)
		agent.start_investigating()
	elif agent.hearing_detection.is_suspicious():
		agent.start_investigating()
	return RUNNING

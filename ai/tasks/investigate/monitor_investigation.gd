@tool
extends NpcBTAction
## Runs alongside the investigating behaviour. SUCCESS when the target is seen
## clearly enough to chase, FAILURE when suspicion has faded.


func _update(delta: float) -> Status:
	var sight: SightDetection = agent.sight_detection
	sight.update_suspicion(delta, false)

	if sight.is_aggro_to_target():
		sight.current_suspicion = sight.investigation_threshold
		agent.start_chasing(sight.detected_target)
		return SUCCESS

	if sight.current_suspicion <= 0 and agent.hearing_detection.current_suspicion <= 0:
		agent.end_investigating()
		return FAILURE
	return RUNNING

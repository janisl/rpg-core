@tool
extends NpcBTAction
## Runs alongside idle and patrolling. Builds up suspicion and starts
## investigating once suspicious; optionally starts chasing a hostile the NPC
## bumps into. Never finishes, higher priority branches take over instead.

@export var chase_when_bumped := false


func _generate_name() -> String:
	return "MonitorCalm" + (" (chase when bumped)" if chase_when_bumped else "")


func _update(delta: float) -> Status:
	var sight: SightDetection = agent.sight_detection
	sight.update_suspicion(delta, true)

	if chase_when_bumped:
		var bumped := _get_bumped_hostile()
		if bumped:
			agent.start_chasing(bumped)
			return RUNNING

	if sight.is_suspicious_of_target():
		agent.set_sight_target(sight.detected_target.global_position)
		agent.start_investigating()
	return RUNNING


func _get_bumped_hostile() -> Actor:
	for i in agent.get_slide_collision_count():
		var collider: Object = agent.get_slide_collision(i).get_collider()
		if agent.is_hostile_towards(collider):
			return collider
	return null

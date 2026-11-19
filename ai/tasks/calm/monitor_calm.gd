@tool
extends NpcBTAction
## Runs alongside idle and patrolling and raises the NPC's awareness from what
## its senses report: investigating when suspicious of something seen or heard,
## alerted when something drew its attention (an active attention point), and
## optionally chasing a hostile it bumps into. Never finishes, the branch for
## the new awareness takes over instead.

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
	elif agent.hearing_detection.is_suspicious():
		agent.start_investigating()
	elif agent.has_attention():
		agent.become_alerted()
	return RUNNING


func _get_bumped_hostile() -> Actor:
	for i in agent.get_slide_collision_count():
		var collider: Object = agent.get_slide_collision(i).get_collider()
		if agent.is_hostile_towards(collider):
			return collider
	return null

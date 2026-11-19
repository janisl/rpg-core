extends NpcBTAction


func _start() -> void:
	agent.chase_action.start()


func _update(delta: float) -> Status:
	var result: NpcChaseAction.ChaseStatus = agent.chase_action.physics_process(delta)
	match result:
		NpcChaseAction.ChaseStatus.CAUGHT:
			return SUCCESS

		NpcChaseAction.ChaseStatus.LOST:
			return FAILURE
	return RUNNING

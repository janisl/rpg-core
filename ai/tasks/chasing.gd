extends BTAction


func _enter() -> void:
	agent.chase_action.start()


func _tick(delta: float) -> Status:
	var result: NpcChaseAction.ChaseStatus = agent.chase_action.physics_process(delta)
	match result:
		NpcChaseAction.ChaseStatus.CAUGHT:
			return SUCCESS

		NpcChaseAction.ChaseStatus.LOST:
			agent.in_chasing = false
			agent.state_chart.send_event("search")
			return FAILURE
	return RUNNING

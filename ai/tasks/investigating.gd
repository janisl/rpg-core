extends BTAction


func _enter() -> void:
	agent.investigate_action.start()


func _tick(delta: float) -> Status:
	var result: NpcInvestigateAction.Result = agent.investigate_action.physics_process(delta)
	if result == NpcInvestigateAction.Result.FOUND:
		return SUCCESS
	elif result == NpcInvestigateAction.Result.NOTHING:
		return FAILURE
	return RUNNING

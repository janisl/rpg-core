extends NpcBTAction


func _start() -> void:
	agent.investigate_action.start()


func _update(delta: float) -> Status:
	var result: NpcInvestigateAction.Result = agent.investigate_action.physics_process(delta)
	if result == NpcInvestigateAction.Result.FOUND:
		return SUCCESS
	elif result == NpcInvestigateAction.Result.NOTHING:
		return FAILURE
	return RUNNING

extends BTAction


func _enter() -> void:
	agent.investigate_action.start()


func _exit() -> void:
	agent.investigate_action.stop()


func _tick(delta: float) -> Status:
	var result: NpcInvestigateAction.Result = agent.investigate_action.physics_process(delta)
	if result == NpcInvestigateAction.Result.NOTHING:
		return FAILURE
	return RUNNING

extends BTAction


func _enter() -> void:
	agent.alerted_action.start()


func _exit() -> void:
	agent.alerted_action.stop()


func _tick(delta: float) -> Status:
	agent.alerted_action.physics_process(delta)
	if agent.alerted_action.has_given_up:
		return SUCCESS
	return RUNNING

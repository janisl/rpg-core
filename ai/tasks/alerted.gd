extends NpcBTAction


func _start() -> void:
	agent.alerted_action.start()


func _tick(delta: float) -> Status:
	agent.alerted_action.physics_process(delta)
	if agent.is_investigating():
		return SUCCESS
	elif agent.alerted_action.has_given_up:
		return SUCCESS
	return RUNNING

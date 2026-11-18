extends BTAction


func _enter() -> void:
	agent.alerted_action.start()


func _tick(delta: float) -> Status:
	agent.alerted_action.physics_process(delta)
	if agent.is_investigating():
		return SUCCESS
	elif agent.alerted_action.has_given_up:
		agent.state_chart.send_event("idle")
		return SUCCESS
	return RUNNING

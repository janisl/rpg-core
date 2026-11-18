extends BTAction


func _enter() -> void:
	agent.search_action.start()


func _exit() -> void:
	agent.search_action.stop()


func _tick(delta: float) -> Status:
	agent.search_action.physics_process(delta)
	if agent.search_action.target_reacquired:
		return SUCCESS
	elif agent.search_action.given_up:
		agent.state_chart.send_event("idle")
		return FAILURE
	return RUNNING

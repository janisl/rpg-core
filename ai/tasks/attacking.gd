extends BTAction


func _enter() -> void:
	agent.attack_action.start()


func _exit() -> void:
	agent.attack_action.stop()


func _tick(delta: float) -> Status:
	if agent.attack_action.physics_process(delta):
		agent.in_attack = false
		agent.state_chart.send_event("chase")
		return SUCCESS
	return RUNNING

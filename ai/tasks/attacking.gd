extends BTAction


func _enter() -> void:
	agent.attack_action.start()


func _exit() -> void:
	agent.attack_action.stop()


func _tick(delta: float) -> Status:
	if agent.attack_action.physics_process(delta):
		return SUCCESS
	return RUNNING

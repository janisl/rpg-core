extends NpcBTAction


func _start() -> void:
	agent.attack_action.start()


func _end() -> void:
	agent.attack_action.stop()


func _update(delta: float) -> Status:
	if agent.attack_action.physics_process(delta):
		return SUCCESS
	return RUNNING

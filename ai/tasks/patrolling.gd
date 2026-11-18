extends BTAction


func _enter() -> void:
	agent.patrol_action.start()


func _tick(delta: float) -> Status:
	agent.patrol_action.physics_process(delta)
	if agent.is_in_combat():
		return SUCCESS
	if agent.is_investigating():
		return SUCCESS
	return RUNNING

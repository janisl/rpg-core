extends BTAction


func _enter() -> void:
	agent.idle_action.start()


func _tick(delta: float) -> Status:
	agent.idle_action.physics_process(delta)
	return SUCCESS

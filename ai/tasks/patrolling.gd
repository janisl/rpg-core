extends BTAction


func _enter() -> void:
	agent.idle_action.start()
	agent.patrol_action.start()


func _tick(delta: float) -> Status:
	agent.patrol_action.physics_process(delta)
	return RUNNING

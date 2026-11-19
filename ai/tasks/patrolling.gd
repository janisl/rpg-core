extends BTAction


func _enter() -> void:
	agent.idle_action.start()
	agent.patrol_action.start()


func _exit() -> void:
	agent.patrol_action.stop()


func _tick(delta: float) -> Status:
	agent.patrol_action.physics_process(delta)
	return RUNNING

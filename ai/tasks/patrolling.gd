extends NpcBTAction


func _start() -> void:
	agent.patrol_action.start()


func _tick(delta: float) -> Status:
	agent.patrol_action.physics_process(delta)
	return RUNNING

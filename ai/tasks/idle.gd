extends NpcBTAction


func _start() -> void:
	agent.idle_action.start()


func _update(delta: float) -> Status:
	agent.idle_action.physics_process(delta)
	return SUCCESS

@tool
extends NpcBTAction

enum Speed { WALK, RUN }

@export var speed := Speed.WALK


func _generate_name() -> String:
	return "SetMoveSpeed %s" % Speed.keys()[speed].capitalize()


func _update(_delta: float) -> Status:
	if speed == Speed.WALK:
		agent.set_walking_speed()
	else:
		agent.set_running_speed()
	return SUCCESS

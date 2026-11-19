@tool
extends NpcBTAction

enum Pose { NEUTRAL, RAISED_WEAPON, ATTACK }

@export var pose := Pose.NEUTRAL


func _generate_name() -> String:
	return "SetUpperBody %s" % Pose.keys()[pose].capitalize()


func _update(_delta: float) -> Status:
	match pose:
		Pose.NEUTRAL:
			agent.set_upper_body_neutral()
		Pose.RAISED_WEAPON:
			agent.set_upper_body_raised_weapon()
		Pose.ATTACK:
			agent.set_upper_body_attack()
	return SUCCESS

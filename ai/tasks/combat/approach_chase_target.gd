@tool
extends NpcBTAction
## Runs towards the chase target. SUCCESS once it's visible and within attack
## range: weapon range minus [member ranged_distance_offset] for ranged
## weapons, otherwise [member melee_distance].

@export var melee_distance := 1.5
@export var ranged_distance_offset := 1.0


func _update(delta: float) -> Status:
	var target: Actor = agent.chase_target
	agent.nav_agent.target_position = target.global_position
	agent.move_npc_to_next_position(delta)

	if agent.sight_detection.check_if_chase_target_in_los():
		var distance := agent.global_position.distance_to(target.global_position) as float
		var weapon_range := agent.get_weapon_range() as float if agent.is_using_weapon() else 0.0
		if weapon_range > 0.0 and distance <= weapon_range - ranged_distance_offset:
			return SUCCESS
		if distance <= melee_distance:
			return SUCCESS
	return RUNNING

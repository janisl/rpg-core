@tool
extends NpcBTAction
## Stores the position of a point on the NPC's patrol path. [constant NEXT]
## advances along the path.

enum Point { NEXT, START }

@export var point := Point.NEXT
@export var output_var: StringName = &"patrol_target"


func _generate_name() -> String:
	return "PickPatrolPoint %s ➜ %s" % [Point.keys()[point].capitalize(), LimboUtility.decorate_var(output_var)]


func _update(_delta: float) -> Status:
	var path: PatrolPath = agent.patrol_path
	if not path:
		return FAILURE
	var patrol_point: PatrolPoint = path.target_next_patrol_point() if point == Point.NEXT else path.starting_patrol_point
	blackboard.set_var(output_var, patrol_point.global_position)
	return SUCCESS

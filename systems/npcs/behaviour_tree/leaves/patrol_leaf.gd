@tool
extends NpcActionLeaf

@export var patrol_point_wait_time := 3.0

var _patrol_action: NpcPatrolAction


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_patrol_action = NpcPatrolAction.new(npc, patrol_point_wait_time)
	add_child(_patrol_action)


func _start() -> void:
	npc.set_upper_body_neutral()
	npc.set_lower_body_walk()
	_patrol_action.start()


func tick(_actor: Node, _blackboard: Blackboard) -> int:
	var bumped_target := npc.find_bumped_hostile_target()
	if bumped_target:
		npc.start_combat(bumped_target)

	_patrol_action.physics_process(get_physics_process_delta_time())
	return RUNNING

@tool
extends NpcActionLeaf


func _start() -> void:
	npc.set_upper_body_neutral()


func tick(_actor: Node, _blackboard: Blackboard) -> int:
	npc.stop_moving(get_physics_process_delta_time())
	return RUNNING

extends NpcStateProcessor

@export var patrol_point_wait_time := 3.0

var _patrol_action: NpcPatrolAction


func _enter_tree() -> void:
	_patrol_action = NpcPatrolAction.new(npc, patrol_point_wait_time)
	add_child(_patrol_action)


func save_state() -> Dictionary:
	return _patrol_action.save_state()


func load_state(state: Dictionary) -> void:
	_patrol_action.load_state(state)


func _on_patrolling_state_entered() -> void:
	_enter_state()
	npc.set_upper_body_neutral()
	_patrol_action.start()


func _on_patrolling_state_exited() -> void:
	_exit_state()


func _on_patrolling_state_physics_processing(delta: float) -> void:
	var bumped_target := npc.find_bumped_hostile_target()
	if bumped_target:
		npc.attention_target = bumped_target
		state_chart.send_event("chase")

	_patrol_action.physics_process(delta)

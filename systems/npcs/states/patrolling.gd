extends NpcStateProcessor


func _on_patrolling_state_entered() -> void:
	npc.patrol_action.start()


func _on_patrolling_state_physics_processing(delta: float) -> void:
	npc.patrol_action.physics_process(delta)
	if npc.is_in_combat():
		state_chart.send_event("chase")
	if npc.is_investigating():
		npc.state_chart.send_event("chase")

extends NpcStateProcessor


func _on_searching_state_entered() -> void:
	_enter_state()
	npc.search_action.start()


func _on_searching_state_exited() -> void:
	npc.search_action.stop()


func _on_searching_state_physics_processing(delta: float) -> void:
	npc.search_action.physics_process(delta)
	if npc.search_action.target_reacquired:
		state_chart.send_event("chase")
	elif npc.search_action.given_up:
		state_chart.send_event("idle")

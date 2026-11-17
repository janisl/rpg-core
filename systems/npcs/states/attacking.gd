extends NpcStateProcessor


func _on_attacking_state_entered() -> void:
	_enter_state()
	npc.attack_action.start()


func _on_attacking_state_exited() -> void:
	npc.attack_action.stop()


func _on_attacking_state_physics_processing(delta: float) -> void:
	if npc.attack_action.physics_process(delta):
		state_chart.send_event("chase")

extends NpcStateProcessor


func _on_investigate_state_entered() -> void:
	npc.investigate_action.start()


func _on_investigate_state_physics_processing(delta: float) -> void:
	var result := npc.investigate_action.physics_process(delta)
	if result == NpcInvestigateAction.Result.FOUND:
		state_chart.send_event("chase")
	elif result == NpcInvestigateAction.Result.NOTHING:
		state_chart.send_event("idle")

extends NpcStateProcessor


func _on_investigate_state_entered() -> void:
	_enter_state()
	npc.investigate_action.start()

func _on_investigate_state_physics_processing(delta: float) -> void:
	npc.investigate_action.physics_process(delta)

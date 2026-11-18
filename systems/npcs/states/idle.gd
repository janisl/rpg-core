extends NpcStateProcessor


func _on_idle_state_entered() -> void:
	npc.idle_action.start()
	if npc.has_patrol_path():
		state_chart.send_event("patrol")


func _on_idle_state_physics_processing(delta: float) -> void:
	if npc.idle_action.physics_process(delta):
		npc.state_chart.send_event("chase")

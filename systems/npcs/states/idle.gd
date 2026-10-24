extends NpcStateProcessor


func _on_idle_state_entered() -> void:
	pass # Replace with function body.


func _on_idle_state_exited() -> void:
	pass # Replace with function body.


func _on_idle_state_physics_processing(delta: float) -> void:
	npc.move_and_slide()

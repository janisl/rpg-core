extends NpcStateProcessor


func _on_chasing_state_entered() -> void:
	npc.in_chasing = true

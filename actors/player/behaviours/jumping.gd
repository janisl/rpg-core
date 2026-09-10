extends PlayerStateBehaviour


func _on_state_processing(_delta: float) -> void:
	if player.velocity.y < 0:
		player.state_chart.send_event("onFalling")

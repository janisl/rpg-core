extends PlayerStateBehaviour


func _on_state_processing(_delta: float) -> void:
	if player and player.get_input_direction().length() > 0:
		player.state_chart.send_event("onMoving")

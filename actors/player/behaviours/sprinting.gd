extends PlayerStateBehaviour


func _on_state_entered() -> void:
	player.sprint()


func _on_state_processing(delta: float) -> void:
	if not Input.is_action_pressed("sprint"):
		player.state_chart.send_event("onWalking")

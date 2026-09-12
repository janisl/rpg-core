extends PlayerStateBehaviour

signal sprinting()


func _on_state_entered() -> void:
	sprinting.emit()


func _on_state_processing(delta: float) -> void:
	if not Input.is_action_pressed("sprint"):
		player.state_chart.send_event("onWalking")

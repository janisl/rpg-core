extends PlayerStateBehaviour

signal walking()


func _on_state_entered() -> void:
	walking.emit()


func _on_state_processing(delta: float) -> void:
	if Input.is_action_pressed("sprint"):
		player.state_chart.send_event("onSprinting")

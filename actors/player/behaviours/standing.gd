extends PlayerStateBehaviour

signal standing()


func _on_state_entered() -> void:
	standing.emit()
	player.try_crouch = false


func _on_state_processing(_delta: float) -> void:
	if player.try_crouch and player.is_on_floor():
		player.state_chart.send_event("onCrouching")


func _on_state_physics_processing(delta: float) -> void:
	player.camera_controller.update_camera_height(delta, player.standing_camera_height)

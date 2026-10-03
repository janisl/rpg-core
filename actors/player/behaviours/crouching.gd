extends PlayerStateBehaviour

signal crouching()


func _on_state_entered() -> void:
	crouching.emit()


func _on_state_processing(_delta: float) -> void:
	if _should_stand_up():
		player.state_chart.send_event("onStanding")


func _on_state_physics_processing(delta: float) -> void:
	player.camera_controller.update_camera_height(delta, player.crouch_camera_height)


func _should_stand_up() -> bool:
	if player.crouch_check.is_colliding():
		return false

	if player.is_on_floor():
		return not player.try_crouch
	else:
		return false

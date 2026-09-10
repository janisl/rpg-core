extends PlayerStateBehaviour


func _on_state_entered() -> void:
	player.stand()


func _on_state_processing(_delta: float) -> void:
	if Input.is_action_pressed("crouch") and player.is_on_floor():
		player.state_chart.send_event("onCrouching")


func _on_state_physics_processing(delta: float) -> void:
	player.camera_controller.update_camera_height(delta, 1)

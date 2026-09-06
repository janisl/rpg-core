class_name PlayerStateCrouching
extends PlayerState


func _on_crouching_state_processing(_delta: float) -> void:
	if not Input.is_action_pressed("crouch") and player.is_on_floor() and not player.crouch_check.is_colliding():
		player.state_chart.send_event("onStanding")


func _on_crouching_state_entered() -> void:
	player.crouch()


func _on_crouching_state_physics_processing(delta: float) -> void:
	player.camera_controller.update_camera_height(delta, -1)

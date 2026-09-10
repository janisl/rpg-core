extends PlayerStateBehaviour


func _on_state_physics_processing(delta: float) -> void:
	if player.is_on_floor():
		if player.check_fall_speed():
			player.camera_effects.add_fall_kick(2.0)

		player.state_chart.send_event("onGrounded")

	player.current_fall_velocity = player.velocity.y

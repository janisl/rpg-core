extends PlayerStateBehaviour


func _on_state_physics_processing(_delta: float) -> void:
	player.previous_velocity = player.velocity

	var speed_modifier = player._sprint_modifier + player._crouch_modifier
	player._speed = player.default_speed + speed_modifier

	player.input_dir = Input.get_vector("left", "right", "forward", "backward")
	var current_velocity = Vector2(player.velocity.x, player.velocity.z)
	var direction := (player.transform.basis * Vector3(player.input_dir.x, 0, player.input_dir.y)).normalized()
	if direction:
		current_velocity = lerp(current_velocity, Vector2(direction.x, direction.z) * player._speed, player.acceleration)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, player.deceleration)

	player.velocity.x = current_velocity.x
	player.velocity.z = current_velocity.y

	player.move_and_slide()

	player.step_handler.handle_step_climbing()

	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.jump()
		player.state_chart.send_event("onAirborne")
		return

	if not player.is_on_floor():
		player.state_chart.send_event("onAirborne")
		return

class_name PlayerAirborneMovementHandler
extends Node

@export_group("References")
@export var player: Player


func _on_walking() -> void:
	pass # Replace with function body.


func _on_sprinting() -> void:
	pass # Replace with function body.


func _on_standing() -> void:
	pass # Replace with function body.


func _on_crouching() -> void:
	pass # Replace with function body.


func _on_handle_airborne_physics(delta: float) -> void:
	player.current_fall_velocity = player.velocity.y

	player.previous_velocity = player.velocity

	player.velocity += player.get_gravity() * delta

	var speed_modifier = player._sprint_modifier + player._crouch_modifier
	player._speed = player.default_speed + speed_modifier

	player.input_dir = Input.get_vector("left", "right", "forward", "backward")
	var current_velocity = Vector2(player.velocity.x, player.velocity.z)
	var direction := (player.transform.basis * Vector3(player.input_dir.x, 0, player.input_dir.y)).normalized()
	if direction:
		current_velocity = lerp(current_velocity, Vector2(direction.x, direction.z) * player._speed, player.acceleration * 0.1)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, player.deceleration * 0.1)

	player.velocity.x = current_velocity.x
	player.velocity.z = current_velocity.y

	player.move_and_slide()

	if player.is_on_floor():
		if player.check_fall_speed():
			player.camera_effects.add_fall_kick(2.0)

		player.state_chart.send_event("onGrounded")
		return

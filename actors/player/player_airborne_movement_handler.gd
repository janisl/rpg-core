class_name PlayerAirborneMovementHandler
extends Node

@export_group("References")
@export var player: Player

@export_group("Movement settings")
@export var acceleration := 0.02
@export var deceleration := 0.05
@export var default_speed := 7.0

@export_group("Effect settings")
@export var fall_velocity_threshold := -5.0
@export var fall_kick := 2.0


func _on_airborne_state_physics_processing(delta: float) -> void:
	var current_fall_velocity = player.velocity.y

	player.velocity += player.get_gravity() * delta

	var speed = default_speed

	var current_velocity = Vector2(player.velocity.x, player.velocity.z)
	var direction := (player.transform.basis * Vector3(player.input_dir.x, 0, player.input_dir.y)).normalized()
	if direction:
		current_velocity = lerp(current_velocity, Vector2(direction.x, direction.z) * speed, acceleration)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration)

	player.velocity.x = current_velocity.x
	player.velocity.z = current_velocity.y

	player.push_away_rigid_bodies()
	player.move_and_slide()

	if player.is_on_floor():
		if current_fall_velocity < fall_velocity_threshold:
			player.camera_effects.add_fall_kick(fall_kick)


func _on_jumping_state_processing(_delta: float) -> void:
	if player.velocity.y < 0:
		player.state_chart.send_event("onFalling")

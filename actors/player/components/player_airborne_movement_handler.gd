class_name PlayerAirborneMovementHandler
extends Node

@export_group("References")
@export var player: Player

@export_group("Movement settings")
@export var acceleration := 0.2
@export var deceleration := 0.5
@export var default_speed := 7.0
@export var sprint_speed := 3.0
@export var crouch_speed := -5.0

@export_group("Effect settings")
@export var fall_velocity_threshold := -5.0
@export var fall_kick := 2.0

var _sprint_modifier := 0.0
var _crouch_modifier := 0.0


func _on_walking() -> void:
	_sprint_modifier = 0


func _on_sprinting() -> void:
	_sprint_modifier = sprint_speed


func _on_standing() -> void:
	_crouch_modifier = 0


func _on_crouching() -> void:
	_crouch_modifier = crouch_speed


func _on_handle_airborne_physics(delta: float) -> void:
	var current_fall_velocity = player.velocity.y

	player.velocity += player.get_gravity() * delta

	var speed_modifier = _sprint_modifier + _crouch_modifier
	var speed = default_speed + speed_modifier

	var current_velocity = Vector2(player.velocity.x, player.velocity.z)
	var direction := (player.transform.basis * Vector3(player.input_dir.x, 0, player.input_dir.y)).normalized()
	if direction:
		current_velocity = lerp(current_velocity, Vector2(direction.x, direction.z) * speed, acceleration * 0.1)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration * 0.1)

	player.velocity.x = current_velocity.x
	player.velocity.z = current_velocity.y

	player.push_away_rigid_bodies()
	player.move_and_slide()

	if player.is_on_floor():
		if current_fall_velocity < fall_velocity_threshold:
			player.camera_effects.add_fall_kick(fall_kick)

		player.state_chart.send_event("onGrounded")
		return

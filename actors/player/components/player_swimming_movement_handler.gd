class_name PlayerSwimmingMovementHandler
extends Node

@export_group("References")
@export var player: Player

@export_group("Movement settings")
@export var swim_speed := 4.0
@export var swim_sprint_speed := 7.0
@export var swim_up_speed := 10.0
@export var gravity_factor := 0.2
@export var damped_factor := 2.0


func _on_handle_swimming_physics(delta: float) -> void:
	player.input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction := (player.camera_effects.global_transform.basis * Vector3(player.input_dir.x, 0, player.input_dir.y)).normalized()

	var new_velocity = player.velocity
	if not player.is_on_floor():
		new_velocity += player.get_gravity() * gravity_factor * delta

	var speed = swim_sprint_speed if Input.is_action_pressed("sprint") else swim_speed
	new_velocity += direction * speed * delta

	if Input.is_action_pressed("jump"):
		new_velocity.y += swim_up_speed * delta

	if Input.is_action_pressed("crouch"):
		new_velocity.y += -swim_up_speed * delta

	new_velocity = new_velocity.lerp(Vector3.ZERO, damped_factor * delta)

	player.velocity = new_velocity
	player.push_away_rigid_bodies()
	player.move_and_slide()

	if not player.is_in_swimmable_area():
		if player.is_on_floor():
			player.state_chart.send_event("onGrounded")
		else:
			player.state_chart.send_event("onAirborne")

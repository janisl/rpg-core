class_name StepHandler
extends Node

const FEET_ADJUSTED_HEIGHT := 0.05
const MIN_STEP_HEIGHT := 0.03
const MIN_MOVEMENT_LENGTH := 0.1
const MIN_DOT_VALUE := 0.5

@export_group("References")
@export var player: Player

@export_group("Step settings")
@export var surface_threshold := 0.3
@export var step_height := 0.5

var step_status


func handle_step_climbing():
	step_status = "No vertical collision etected"
	for i in player.get_slide_collision_count():
		var collision := player.get_slide_collision(i)
		if _is_vertical_surface(collision):
			var measured_height := _measure_step_height(collision)
			if measured_height > MIN_STEP_HEIGHT and measured_height <= step_height and is_valid_step_direction(collision):
				player.global_position.y += measured_height
				player.velocity = player.previous_velocity
				player.camera_controller.smooth_step(measured_height)
				step_status = "Step Found! Height: " + str(measured_height)
			else:
				step_status = "Step too high: " + str(measured_height)
			break

	#print(step_status)


func _is_vertical_surface(collision: KinematicCollision3D) -> bool:
	var normal := collision.get_normal()
	if abs(normal.y) <= surface_threshold:
		return true

	return _check_collision_surface(collision)


func _check_collision_surface(collision: KinematicCollision3D) -> bool:
	var space_state := player.get_world_3d().direct_space_state
	var collision_point := collision.get_position()

	var player_feet := _get_player_feet_position()
	collision_point.y = player_feet.y

	var query := PhysicsRayQueryParameters3D.create(player_feet, collision_point)
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]

	var result := space_state.intersect_ray(query)
	if result and abs(result.normal.y) <= surface_threshold:
		return true

	return false


func _get_player_feet_position() -> Vector3:
	var feet_pos := player.global_position
	feet_pos.y += FEET_ADJUSTED_HEIGHT
	return feet_pos


func _measure_step_height(collision: KinematicCollision3D) -> float:
	var space_state := player.get_world_3d().direct_space_state
	var collision_point := collision.get_position()

	var player_feet := _get_player_feet_position()
	var player_head_y: float = player.global_position.y + (player.standing_collision.shape.height / 2.0)

	var ray_start := Vector3(collision_point.x, player_head_y, collision_point.z)
	var ray_end := Vector3(collision_point.x, player_feet.y, collision_point.z)

	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]

	var result := space_state.intersect_ray(query)
	if result:
		return result.position.y - player_feet.y

	return 0.0


func is_valid_step_direction(collision: KinematicCollision3D) -> bool:
	var collision_normal := collision.get_normal()
	var input_dir := player.input_dir
	var movement_direction := player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	if movement_direction.length() > MIN_MOVEMENT_LENGTH:
		movement_direction = movement_direction.normalized()
		var dot_product = movement_direction.dot(-collision_normal)
		return dot_product > MIN_DOT_VALUE
	return false

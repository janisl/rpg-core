class_name PlayerSittingHandler
extends Node

var current_seat: Seat

var _original_position: Transform3D
var _original_neck_basis := Basis()
var _currently_tweening := false
var _displacement_position: Vector3

@onready var player: Player = $"../.."


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_ref(state, &"current_seat", current_seat)
	if current_seat:
		state[&"original_position"] = _original_position
		state[&"currently_tweening"] = _currently_tweening
		state[&"displacement_position"] = _displacement_position
		state[&"original_neck_basis"] = _original_neck_basis
	return state


func load_state(state: Dictionary) -> void:
	current_seat = SaveUtils.load_ref(state, &"current_seat")
	if current_seat:
		_original_position = state.get(&"original_position", Transform3D())
		_currently_tweening = state.get(&"currently_tweening", false)
		_displacement_position = state.get(&"displacement_position", Vector3.ZERO)
		_original_neck_basis = state.get(&"_original_neck_basis", Basis())


func sit_requested(seat: Seat) -> void:
	_sit_down(seat, false)


func seat_move_requested(seat: Seat) -> void:
	_sit_down(seat, true)


func stand_requested() -> void:
	_stand_up()


func _on_sitting_state_physics_processing(_delta: float) -> void:
	if not _currently_tweening:
		player.global_transform = _get_sitting_transform()


func _on_sitting_state_head_physics_processing(_delta: float) -> void:
	var input := player.input_controller.consume_look_delta()
	if _currently_tweening:
		return

	player.camera_controller.rotate_y(input.x)

	player.camera_controller.head.rotate_x(input.y)
	player.camera_controller.head.rotation.x = clamp(player.camera_controller.head.rotation.x, deg_to_rad(-current_seat.vertical_look_angle), deg_to_rad(current_seat.vertical_look_angle))


func _sit_down(seat: Seat, is_changing_seats: bool) -> void:
	current_seat = seat
	player.state_chart.set_expression_property(&"is_sitting", true)
	if not is_changing_seats:
		_original_position = player.global_transform
		_original_neck_basis = player.camera_controller.transform.basis
		_displacement_position = current_seat.global_transform.origin - player.global_transform.origin

	_currently_tweening = true
	var tween := create_tween()
	tween.tween_property(player, "global_transform", _get_sitting_transform(), current_seat.tween_duration)
	tween.tween_callback(_sit_down_finished)


func _sit_down_finished() -> void:
	player.standing_collision.disabled = true
	player.crouching_collision.disabled = true
	_currently_tweening = false


func _stand_up() -> void:
	match current_seat.placement_on_leave:
		Seat.PlacementOnLeave.ORIGINAL:
			_move_to_original_position()
		Seat.PlacementOnLeave.DISPLACEMENT:
			_move_to_displacement_position()
		Seat.PlacementOnLeave.TRANSFORM:
			_move_to_leave_node()
		Seat.PlacementOnLeave.AUTO:
			_move_to_nearby_location()


func _move_to_original_position() -> void:
	_currently_tweening = true
	var tween := create_tween()
	tween.tween_property(player, "global_transform", _original_position, current_seat.tween_duration)
	tween.tween_property(player.camera_controller, "transform:basis", _original_neck_basis, current_seat.rotation_tween_duration)
	tween.tween_callback(_stand_up_finished)


func _move_to_displacement_position() -> void:
	var new_position := current_seat.global_transform.origin - _displacement_position
	var new_transform := player.global_transform
	new_transform.origin = new_position
	var tween := create_tween()
	tween.tween_property(player, "global_transform", new_transform, current_seat.tween_duration)
	tween.tween_property(player.camera_controller, "transform:basis", _original_neck_basis, current_seat.rotation_tween_duration)
	tween.tween_callback(_stand_up_finished)


func _move_to_leave_node() -> void:
	_currently_tweening = true
	assert(current_seat.leave_node_path)
	var leave_node := current_seat.get_node(current_seat.leave_node_path)
	if leave_node:
		var tween := create_tween()
		tween.tween_property(player, "global_transform", leave_node.global_transform, current_seat.tween_duration)
		tween.tween_property(player.camera_controller, "transform:basis", _original_neck_basis, current_seat.rotation_tween_duration)
		tween.tween_callback(_stand_up_finished)
	else:
		_move_to_original_position()


func _move_to_nearby_location() -> void:
	var seat_position := current_seat.global_transform.origin
	var exit_distance := 1.0
	var max_distance := 10.0
	var step_increase := 0.5
	var max_attempts := 10
	var navmesh_offset_y := 0.25
	var attempts := 0

	while attempts < max_attempts:
		var random_direction := Vector3(
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1)
		).normalized()

		var candidate_pos := seat_position + (random_direction * exit_distance)
		candidate_pos.y = navmesh_offset_y

		player.navigation_agent.target_position = candidate_pos

		if player.navigation_agent.is_navigation_finished():
			_currently_tweening = true
			var tween := create_tween()
			tween.tween_property(player, "global_transform:origin", player.navigation_agent.target_position, current_seat.tween_duration)
			tween.tween_property(player.camera_controller, "transform:basis", _original_neck_basis, current_seat.rotation_tween_duration)
			tween.tween_callback(_stand_up_finished)
			return

		exit_distance += step_increase
		attempts += 1

		if exit_distance > max_distance:
			exit_distance = 1

	_move_to_leave_node()


func _stand_up_finished() -> void:
	player.standing_collision.disabled = false
	player.camera_controller.transform.basis = _original_neck_basis
	_currently_tweening = false
	player.state_chart.set_expression_property(&"is_sitting", false)
	current_seat = null


func _get_sitting_transform() -> Transform3D:
	var transform := Transform3D(_original_position.basis)
	return current_seat.sit_position_node.global_transform * transform

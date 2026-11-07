class_name PlayerSittingHandler
extends Node

var current_seat: Seat

var _original_position: Transform3D
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
	return state


func load_state(state: Dictionary) -> void:
	current_seat = SaveUtils.load_ref(state, &"current_seat")
	if current_seat:
		_original_position = state.get(&"original_position", Transform3D())
		_currently_tweening = state.get(&"currently_tweening", false)
		_displacement_position = state.get(&"displacement_position", Vector3.ZERO)


func sit_requested(seat: Seat) -> void:
	current_seat = seat
	_sit_down()


func stand_requested() -> void:
	_stand_up()


func _on_sitting_state_physics_processing(_delta: float) -> void:
	if not _currently_tweening:
		player.global_transform = _get_sitting_transform()


func _sit_down() -> void:
	player.state_chart.set_expression_property(&"is_sitting", true)
	_original_position = player.global_transform
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


func _move_to_original_position() -> void:
	_currently_tweening = true
	var tween := create_tween()
	tween.tween_property(player, "global_transform", _original_position, current_seat.tween_duration)
	tween.tween_callback(_stand_up_finished)


func _move_to_displacement_position() -> void:
	var new_position := current_seat.global_transform.origin - _displacement_position
	var new_transform := player.global_transform
	new_transform.origin = new_position
	var tween := create_tween()
	tween.tween_property(player, "global_transform", new_transform, current_seat.tween_duration)
	tween.tween_callback(_stand_up_finished)


func _move_to_leave_node() -> void:
	_currently_tweening = true
	assert(current_seat.leave_node_path)
	var leave_node := current_seat.get_node(current_seat.leave_node_path)
	if leave_node:
		var tween := create_tween()
		tween.tween_property(player, "global_transform", leave_node.global_transform, current_seat.tween_duration)
		tween.tween_callback(_stand_up_finished)
	else:
		_move_to_original_position()


func _stand_up_finished() -> void:
	player.standing_collision.disabled = false
	_currently_tweening = false
	player.state_chart.set_expression_property(&"is_sitting", false)
	current_seat = null


func _get_sitting_transform() -> Transform3D:
	var transform := Transform3D(_original_position.basis)
	return current_seat.sit_position_node.global_transform * transform

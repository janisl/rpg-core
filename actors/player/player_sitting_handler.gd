class_name PlayerSittingHandler
extends Node

var current_seat: Seat

var _original_position: Transform3D

@onready var player: Player = $"../.."


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_ref(state, &"current_seat", current_seat)
	if current_seat:
		state[&"original_position"] = _original_position
	return state


func load_state(state: Dictionary) -> void:
	current_seat = SaveUtils.load_ref(state, &"current_seat")
	if current_seat:
		_original_position = state.get(&"original_position", Transform3D())


func sit_requested(seat: Seat) -> void:
	current_seat = seat
	_sit_down()


func _sit_down() -> void:
	player.state_chart.set_expression_property(&"is_sitting", true)
	_original_position = player.global_transform
	var tween := create_tween()
	tween.tween_property(player, "global_transform", _get_sitting_transform(), current_seat.tween_duration)
	tween.tween_callback(_sit_down_finished)


func _sit_down_finished() -> void:
	player.standing_collision.disabled = true
	player.crouching_collision.disabled = true


func _get_sitting_transform() -> Transform3D:
	var transform := Transform3D(_original_position.basis)
	return current_seat.sit_position_node.global_transform * transform

class_name PlayerSittingHandler
extends Node

var current_seat: Seat

var _original_position: Transform3D
var _currently_tweening := false

@onready var player: Player = $"../.."


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_ref(state, &"current_seat", current_seat)
	if current_seat:
		state[&"original_position"] = _original_position
		state[&"currently_tweening"] = _currently_tweening
	return state


func load_state(state: Dictionary) -> void:
	current_seat = SaveUtils.load_ref(state, &"current_seat")
	if current_seat:
		_original_position = state.get(&"original_position", Transform3D())
		_currently_tweening = state.get(&"currently_tweening", false)


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

	_currently_tweening = true
	var tween := create_tween()
	tween.tween_property(player, "global_transform", _get_sitting_transform(), current_seat.tween_duration)
	tween.tween_callback(_sit_down_finished)


func _sit_down_finished() -> void:
	player.standing_collision.disabled = true
	player.crouching_collision.disabled = true
	_currently_tweening = false


func _stand_up() -> void:
			_move_to_original_position()


func _move_to_original_position() -> void:
	_currently_tweening = true
	var tween := create_tween()
	tween.tween_property(player, "global_transform", _original_position, current_seat.tween_duration)
	tween.tween_callback(_stand_up_finished)


func _stand_up_finished() -> void:
	player.standing_collision.disabled = false
	_currently_tweening = false
	player.state_chart.set_expression_property(&"is_sitting", false)
	current_seat = null


func _get_sitting_transform() -> Transform3D:
	var transform := Transform3D(_original_position.basis)
	return current_seat.sit_position_node.global_transform * transform

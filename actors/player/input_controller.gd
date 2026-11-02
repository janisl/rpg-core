class_name InputController
extends Node

var move_input := Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if (
			event.is_action("move_forward")
			or event.is_action("move_backward")
			or event.is_action("move_left")
			or event.is_action("move_right")):
		move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

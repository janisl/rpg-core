class_name InputController
extends Node

@export_group("Input device settings")
@export_range(0, 10, 0.001, "radians_as_degrees") var mouse_sensitivity := 0.001
@export var joypad_deadzone := 0.25
@export_range(0, 10, 0.001, "radians_as_degrees") var joypad_horizontal_sensitivity := deg_to_rad(2.0)
@export_range(0, 10, 0.001, "radians_as_degrees") var joypad_vertical_sensitivity := deg_to_rad(2.0)
@export var invert_y_axis := false

var move_input := Vector2.ZERO
var look_delta := Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var input: Vector2
		input.x = -event.relative.x * mouse_sensitivity
		input.y = -event.relative.y * mouse_sensitivity
		_update_look_delta(input)

	if event is InputEventJoypadMotion:
		var input := Vector2.ZERO

		if event.get_axis() == 2:
			if abs(event.get_axis_value()) > joypad_deadzone:
				input.x = -event.get_axis_value() * joypad_vertical_sensitivity

		if event.get_axis() == 3:
			if abs(event.get_axis_value()) > joypad_deadzone:
				input.y = -event.get_axis_value() * joypad_horizontal_sensitivity

		if input:
			_update_look_delta(input)

	if (event.is_action("move_forward")
			or event.is_action("move_backward")
			or event.is_action("move_left")
			or event.is_action("move_right")):
		move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")


func consume_look_delta() -> Vector2:
	var result := look_delta
	look_delta = Vector2.ZERO
	return result


func _update_look_delta(input: Vector2) -> void:
	if invert_y_axis:
		input.y *= -1

	look_delta += input

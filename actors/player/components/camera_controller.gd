class_name CameraController
extends Node3D

@export_group("References")
@export var player: Player

@export_group("Camera settings")
@export_range(-90, -60, 0.1, "radians_as_degrees") var tilt_lower_limit := -PI / 2
@export_range(60, 90, 0.1, "radians_as_degrees") var tilt_upper_limit := PI / 2

@export_group("Input device settings")
@export_range(0, 10, 0.001, "radians_as_degrees") var mouse_sensitivity := 0.001
@export var joypad_deadzone := 0.25
@export_range(0, 10, 0.001, "radians_as_degrees") var joypad_horizontal_sensitivity := deg_to_rad(2.0)
@export_range(0, 10, 0.001, "radians_as_degrees") var joypad_vertical_sensitivity := deg_to_rad(2.0)
@export var invert_y_axis := false

@export_group("Smoothing")
@export var crouch_speed: float = 3.0
@export var step_speed: float = 8.0

var _target_height : float
var _step_smoothing := false

var _offset_height : float

@onready var head: Node3D = $Head


func _ready() -> void:
	_offset_height = player.standing_camera_height
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var input: Vector2
		input.x = -event.relative.x * mouse_sensitivity
		input.y = -event.relative.y * mouse_sensitivity
		_update_camera_rotation(input)
	elif event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventJoypadMotion:
		var input := Vector2.ZERO

		if event.get_axis() == 2:
			if abs(event.get_axis_value()) > joypad_deadzone:
				input.x = -event.get_axis_value() * joypad_vertical_sensitivity

		if event.get_axis() == 3:
			if abs(event.get_axis_value()) > joypad_deadzone:
				input.y = -event.get_axis_value() * joypad_horizontal_sensitivity

		if input:
			_update_camera_rotation(input)


func _process(delta: float) -> void:
	if _step_smoothing:
		_target_height = lerp(_target_height, 0.0, step_speed * delta)
		if abs(_target_height) < 0.01:
			_target_height = 0.0
			_step_smoothing = false

	position.y = _offset_height + _target_height


func update_camera_height(delta: float, target_height: float) -> void:
	_offset_height = move_toward(_offset_height, target_height, crouch_speed * delta)


func smooth_step(height_change: float) -> void:
	_target_height -= height_change
	_step_smoothing = true

func _update_camera_rotation(input: Vector2) -> void:
	if invert_y_axis:
		input.y *= -1

	player.rotate_y(input.x)

	head.rotate_x(input.y)
	head.rotation.x = clampf(head.rotation.x, tilt_lower_limit, tilt_upper_limit)

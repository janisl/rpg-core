class_name CameraController
extends Node3D

const DEFAULT_HEIGHT: float = 1.6

@export_group("References")
@export var player: Player
@export_group("Camera settings")
@export var mouse_sensitivity := 0.001
@export_range(-90, -60, 0.1, "radians_as_degrees") var tilt_lower_limit := -PI / 2
@export_range(60, 90, 0.1, "radians_as_degrees") var tilt_upper_limit := PI / 2
@export_group("Crouch vertical movement")
@export var crouch_offset: float = 0.8
@export var crouch_speed: float = 3.0
@export_group("Step smoothing")
@export var step_speed: float = 8.0

var _rotation : Vector3

var _target_height : float
var _step_smoothing := false

var offset_height : float


func _ready() -> void:
	_rotation = player.rotation
	offset_height = DEFAULT_HEIGHT
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


func _process(delta: float) -> void:
	if _step_smoothing:
		_target_height = lerp(_target_height, 0.0, step_speed * delta)
		if abs(_target_height) < 0.01:
			_target_height = 0.0
			_step_smoothing = false

	position.y = offset_height + _target_height


func update_camera_height(delta: float, direction: int) -> void:
	if offset_height >= crouch_offset - 0.0001 and offset_height <= DEFAULT_HEIGHT + 0.0001:
		offset_height = clampf(offset_height + (crouch_speed * direction) * delta, crouch_offset, DEFAULT_HEIGHT)


func smooth_step(height_change: float) -> void:
	_target_height -= height_change
	_step_smoothing = true

func _update_camera_rotation(input: Vector2) -> void:
	_rotation.x += input.y
	_rotation.y += input.x
	_rotation.x = clampf(_rotation.x, tilt_lower_limit, tilt_upper_limit)

	var player_rotation = Vector3(0, _rotation.y, 0)
	var camera_rortation = Vector3(_rotation.x, 0, 0)

	player.update_rotation(player_rotation)
	transform.basis = Basis.from_euler(camera_rortation)
	rotation.z = 0

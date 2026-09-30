class_name CameraController
extends Node3D

@export_group("References")
@export var player: Player

@export_group("Camera settings")
@export var mouse_sensitivity := 0.001
@export_range(-90, -60, 0.1, "radians_as_degrees") var tilt_lower_limit := -PI / 2
@export_range(60, 90, 0.1, "radians_as_degrees") var tilt_upper_limit := PI / 2

@export_group("Smoothing")
@export var crouch_speed: float = 3.0
@export var step_speed: float = 8.0

var _rotation : Vector3

var _target_height : float
var _step_smoothing := false

var offset_height : float

@onready var head: Node3D = $Head


func _ready() -> void:
	_rotation = player.rotation
	offset_height = player.standing_camera_height
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


func update_camera_height(delta: float, target_height: float) -> void:
	offset_height = move_toward(offset_height, target_height, crouch_speed * delta)


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
	head.transform.basis = Basis.from_euler(camera_rortation)
	head.rotation.z = 0

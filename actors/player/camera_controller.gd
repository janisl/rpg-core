class_name CameraController
extends Node3D

@export_group("References")
@export var player: Player

@export_group("Camera settings")
@export_range(-90, -60, 0.1, "radians_as_degrees") var tilt_lower_limit := -PI / 2
@export_range(60, 90, 0.1, "radians_as_degrees") var tilt_upper_limit := PI / 2

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
	add_to_group("persist_component")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
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

	position.y = _offset_height + _target_height


func _physics_process(_delta: float) -> void:
	_update_camera_rotation(player.input_controller.consume_look_delta())


func update_camera_height(delta: float, target_height: float) -> void:
	_offset_height = move_toward(_offset_height, target_height, crouch_speed * delta)


func smooth_step(height_change: float) -> void:
	_target_height -= height_change
	_step_smoothing = true

func _update_camera_rotation(input: Vector2) -> void:
	player.rotate_y(input.x)

	head.rotate_x(input.y)
	head.rotation.x = clampf(head.rotation.x, tilt_lower_limit, tilt_upper_limit)


func save_state() -> Dictionary:
	return {
		&"rotation" : rotation,
		&"head_rotation" : head.rotation,
		&"target_height" : _target_height,
		&"step_smoothing" : _step_smoothing,
		&"offset_height" : _offset_height,
	}


func load_state(state: Dictionary) -> void:
	rotation = state.get(&"rotation", Vector3.ZERO)
	head.rotation = state.get(&"head_rotation", Vector3.ZERO)
	_target_height = state.get(&"target_height", 0.0)
	_step_smoothing = state.get(&"step_smoothing", false)
	_offset_height = state.get(&"offset_height", _offset_height)

	position.y = _offset_height + _target_height

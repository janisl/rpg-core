class_name CameraController
extends Node3D

@export_group("References")
@export var player: Player

@export_group("Camera settings")
@export_range(-90, -60, 0.1, "radians_as_degrees") var tilt_lower_limit := -PI / 2
@export_range(60, 90, 0.1, "radians_as_degrees") var tilt_upper_limit := PI / 2
@export_range(0, 180, 0.1, "radians_as_degrees") var free_look_limit := deg_to_rad(120)

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


func _process(delta: float) -> void:
	if _step_smoothing:
		_target_height = lerp(_target_height, 0.0, step_speed * delta)
		if abs(_target_height) < 0.01:
			_target_height = 0.0
			_step_smoothing = false

	position.y = _offset_height + _target_height


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


func update_camera_height(delta: float, target_height: float) -> void:
	_offset_height = move_toward(_offset_height, target_height, crouch_speed * delta)


func smooth_step(height_change: float) -> void:
	_target_height -= height_change
	_step_smoothing = true


func _update_camera_rotation(input: Vector2, free_looking: bool) -> void:
	if free_looking:
		rotate_y(input.x)
		rotation.y = clamp(rotation.y, -free_look_limit, free_look_limit)
	else:
		player.rotate_y(input.x)

	head.rotate_x(input.y)
	head.rotation.x = clampf(head.rotation.x, tilt_lower_limit, tilt_upper_limit)


func _on_default_state_physics_processing(_delta: float) -> void:
	_update_camera_rotation(player.input_controller.consume_look_delta(), false)


func _on_sliding_state_physics_processing(_delta: float) -> void:
	_update_camera_rotation(player.input_controller.consume_look_delta(), true)


func _on_sliding_state_entered() -> void:
	player.camera_effects.set_slide_tilt(deg_to_rad(4.0))


func _on_sliding_state_exited() -> void:
	player.rotation.y += rotation.y
	rotation.y = 0
	player.camera_effects.set_slide_tilt(0.0)

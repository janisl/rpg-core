class_name CameraController
extends Node3D

const DEFAULT_HEIGHT: float = 0.7

@export_group("References")
@export var player: Player
@export_group("Camera settings")
@export var mouse_sensitivity := 0.001
@export_range(-90, -60) var tilt_lower_limit: int = -90
@export_range(60, 90) var tilt_upper_limit: int = 90
@export_group("Crouch vertical movement")
@export var crouch_offset: float = -0.1
@export var crouch_speed: float = 3.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x * mouse_sensitivity)
		rotation.x = rotation.x - event.relative.y * mouse_sensitivity
		rotation.x = clampf(rotation.x, deg_to_rad(tilt_lower_limit), deg_to_rad(tilt_upper_limit))
	elif event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func update_camera_height(delta: float, direction: int) -> void:
	if position.y >= crouch_offset - 0.0001 and position.y <= DEFAULT_HEIGHT + 0.0001:
		position.y = clampf(position.y + (crouch_speed * direction) * delta, crouch_offset, DEFAULT_HEIGHT)

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

var current_rotation : Vector3


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var input: Vector2
		input.x = -event.relative.x * mouse_sensitivity
		input.y = -event.relative.y * mouse_sensitivity
		update_camera_rotation(input)
	elif event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func update_camera_rotation(input: Vector2) -> void:
	current_rotation.x += input.y
	current_rotation.y += input.x
	current_rotation.x = clampf(current_rotation.x, deg_to_rad(tilt_lower_limit), deg_to_rad(tilt_upper_limit))

	var player_rotation = Vector3(0, current_rotation.y, 0)
	var camera_rortation = Vector3(current_rotation.x, 0, 0)

	player.update_rotation(player_rotation)
	transform.basis = Basis.from_euler(camera_rortation)
	rotation.z = 0


func update_camera_height(delta: float, direction: int) -> void:
	if position.y >= crouch_offset - 0.0001 and position.y <= DEFAULT_HEIGHT + 0.0001:
		position.y = clampf(position.y + (crouch_speed * direction) * delta, crouch_offset, DEFAULT_HEIGHT)

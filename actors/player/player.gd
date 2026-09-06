class_name Player
extends Actor

const STOP_SPEED = 16.0
const JUMP_VELOCITY = 4.5

@export_group("Mouse capture settings")
@export var mouse_sensitivity := 0.001
@export_range(-90, -60) var tilt_lower_limit: int = -90
@export_range(60, 90) var tilt_upper_limit: int = 90
@export_group("Movement settings")
@export var acceleration_speed: float = 8.0
@export var deceleration_speed: float = 12.0

@onready var camera_controller: Node3D = $CameraController

var speed: float = 5.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_controller.rotation.x = camera_controller.rotation.x - event.relative.y * mouse_sensitivity
		camera_controller.rotation.x = clampf(camera_controller.rotation.x, deg_to_rad(tilt_lower_limit), deg_to_rad(tilt_upper_limit))
	elif event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var current_velocity = Vector2(velocity.x, velocity.z)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var acceleration = acceleration_speed * delta
	var deceleration = deceleration_speed * delta
	if direction:
		current_velocity = lerp(current_velocity, Vector2(direction.x, direction.z) * speed, acceleration)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration)

	velocity.x = current_velocity.x
	velocity.z = current_velocity.y

	move_and_slide()

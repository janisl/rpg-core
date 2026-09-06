class_name Player
extends Actor

const SPEED = 5.0
const STOP_SPEED = 16.0
const JUMP_VELOCITY = 4.5

@export_group("Mouse capture settings")
@export var mouse_sensitivity := 0.001
@export_range(-90, -60) var tilt_lower_limit: int = -90
@export_range(60, 90) var tilt_upper_limit: int = 90

@onready var camera_controller: Node3D = $CameraController


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

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		stop_moving(delta)

	move_and_slide()


func stop_moving(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, STOP_SPEED * delta)
	velocity.z = move_toward(velocity.z, 0, STOP_SPEED * delta)

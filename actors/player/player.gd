class_name Player
extends Actor

const STOP_SPEED = 16.0
const JUMP_VELOCITY = 4.5

@export_group("References")
@export var camera_controller: CameraController
@export var state_chart: StateChart
@export var standing_collision: CollisionShape3D
@export var crouching_collision: CollisionShape3D
@export var crouch_check: ShapeCast3D
@export_group("Movement settings")
@export var acceleration: float = 0.2
@export var deceleration: float = 0.5
@export var default_speed: float = 7.0
@export var sprint_speed: float = 3.0
@export var crouch_speed: float = -5.0

var speed: float = 0
var sprint_modifier: float = 0
var crouch_modifier: float = 0
var input_dir := Vector2.ZERO


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var speed_modifier = sprint_modifier + crouch_modifier
	speed = default_speed + speed_modifier

	input_dir = Input.get_vector("left", "right", "forward", "backward")
	var current_velocity = Vector2(velocity.x, velocity.z)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		current_velocity = lerp(current_velocity, Vector2(direction.x, direction.z) * speed, acceleration)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration)

	velocity.x = current_velocity.x
	velocity.z = current_velocity.y

	move_and_slide()


func walk() -> void:
	sprint_modifier = 0


func sprint() -> void:
	sprint_modifier = sprint_speed


func stand() -> void:
	crouch_modifier = 0
	standing_collision.disabled = false
	crouching_collision.disabled = true


func crouch() -> void:
	crouch_modifier = crouch_speed
	standing_collision.disabled = true
	crouching_collision.disabled = false

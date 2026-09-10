class_name Player
extends Actor

const STOP_SPEED = 16.0

@export_group("References")
@export var camera_controller: CameraController
@export var camera_effects: CameraEffects
@export var state_chart: StateChart
@export var standing_collision: CollisionShape3D
@export var crouching_collision: CollisionShape3D
@export var crouch_check: ShapeCast3D
@export var interaction_ray_cast: InteractionRayCast
@export var step_handler: StepHandler
@export_group("Movement settings")
@export var acceleration := 0.2
@export var deceleration := 0.5
@export var default_speed := 7.0
@export var sprint_speed := 3.0
@export var crouch_speed := -5.0
@export var jump_velocity := 5.0
@export_group("Effect settings")
@export var fall_velocity_threshold := -5.0

var _speed := 0.0
var _sprint_modifier := 0.0
var _crouch_modifier := 0.0
var _input_dir := Vector2.ZERO
var current_fall_velocity := 0.0
var previous_velocity := Vector3.ZERO


func _process(_delta: float) -> void:
	state_chart.set_expression_property("Looking at: ", interaction_ray_cast.current_object)


func _physics_process(delta: float) -> void:
	previous_velocity = velocity

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	var speed_modifier = _sprint_modifier + _crouch_modifier
	_speed = default_speed + speed_modifier

	_input_dir = Input.get_vector("left", "right", "forward", "backward")
	var current_velocity = Vector2(velocity.x, velocity.z)
	var direction := (transform.basis * Vector3(_input_dir.x, 0, _input_dir.y)).normalized()
	if direction:
		current_velocity = lerp(current_velocity, Vector2(direction.x, direction.z) * _speed, acceleration)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration)

	velocity.x = current_velocity.x
	velocity.z = current_velocity.y

	move_and_slide()

	if is_on_floor():
		step_handler.handle_step_climbing()


func update_rotation(value: Vector3) -> void:
	global_transform.basis = Basis.from_euler(value)


func walk() -> void:
	_sprint_modifier = 0


func sprint() -> void:
	_sprint_modifier = sprint_speed


func stand() -> void:
	_crouch_modifier = 0
	standing_collision.disabled = false
	crouching_collision.disabled = true


func crouch() -> void:
	_crouch_modifier = crouch_speed
	standing_collision.disabled = true
	crouching_collision.disabled = false


func jump() -> void:
	velocity.y += jump_velocity


func check_fall_speed() -> bool:
	if current_fall_velocity < fall_velocity_threshold:
		current_fall_velocity = 0.0
		return true
	else:
		current_fall_velocity = 0.0
		return false


func get_input_direction() -> Vector2:
	return _input_dir

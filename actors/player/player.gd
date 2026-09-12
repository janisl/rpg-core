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
var input_dir := Vector2.ZERO
var current_fall_velocity := 0.0
var previous_velocity := Vector3.ZERO

@onready var stairs_ahead_ray_cast: RayCast3D = $StairsAheadRayCast
@onready var stairs_below_ray_cast: RayCast3D = $StairsBelowRayCast


func _process(_delta: float) -> void:
	state_chart.set_expression_property("Looking at: ", interaction_ray_cast.current_object)


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

class_name Player
extends Actor

@export_group("References")
@export var camera_controller: CameraController
@export var camera_effects: CameraEffects
@export var state_chart: StateChart
@export var standing_collision: CollisionShape3D
@export var crouching_collision: CollisionShape3D
@export var crouch_check: ShapeCast3D
@export var interaction_ray_cast: InteractionRayCast
@export var stairs_ahead_ray_cast: RayCast3D
@export var stairs_below_ray_cast: RayCast3D
@export var weapon_controller: WeaponController

@export_group("Movement settings")
@export var jump_velocity := 5.0

var input_dir := Vector2.ZERO


func _process(_delta: float) -> void:
	state_chart.set_expression_property("Looking at: ", interaction_ray_cast.current_object)


func update_rotation(value: Vector3) -> void:
	global_transform.basis = Basis.from_euler(value)


func jump() -> void:
	velocity.y += jump_velocity


func _on_standing() -> void:
	standing_collision.disabled = false
	crouching_collision.disabled = true


func _on_crouching() -> void:
	standing_collision.disabled = true
	crouching_collision.disabled = false

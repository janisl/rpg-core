class_name CameraEffects
extends Camera3D

@export_group("References")
@export var player: Player

@export_group("Run tilt")
@export var enable_tilt := true
@export var run_pitch := 0.1
@export var run_roll := 0.25
@export var max_pitch := 1.0
@export var max_roll := 2.5

@export_group("Fall kick")
@export var enable_fall_kick := true
@export var fall_time := 0.3

@export_group("Damage kick")
@export var enable_damage_kick := true
@export var damage_time := 0.3

@export_group("Weapon kick")
@export var enable_weapon_kick := true
@export var weapon_decay := 0.5

var _fall_value := 0.0
var _fall_timer := 0.0

var _damage_pitch := 0.0
var _damage_roll := 0.0
var _damage_timer := 0.0

var _weapon_kick_angles := Vector3.ZERO


func _process(delta: float) -> void:
	_calcuate_view_offset(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		add_weapon_kick(2.0, 2.0, 2.0)


func add_fall_kick(fall_strength: float) -> void:
	_fall_value = deg_to_rad(fall_strength)
	_fall_timer = fall_time


func add_weapon_kick(pitch: float, yaw: float, roll: float) -> void:
	_weapon_kick_angles.x += deg_to_rad(pitch)
	_weapon_kick_angles.y += deg_to_rad(randf_range(-yaw, yaw))
	_weapon_kick_angles.z += deg_to_rad(randf_range(-roll, roll))


func add_damage_kick(pitch: float, roll: float, source: Vector3) -> void:
	var forward := global_transform.basis.z
	var right := global_transform.basis.x
	var direction = global_position.direction_to(source)
	var forward_dot = direction.dot(forward)
	var right_dot = direction.dot(right)
	_damage_pitch = deg_to_rad(pitch) * forward_dot
	_damage_roll = deg_to_rad(roll) * right_dot
	_damage_timer = damage_time


func _calcuate_view_offset(delta: float) -> void:
	if not player:
		return

	_fall_timer -= delta
	_damage_timer -= delta

	var velocity := player.velocity

	var angles := Vector3.ZERO
	var offset := Vector3.ZERO

	if enable_tilt:
		var forward := global_transform.basis.z
		var right := global_transform.basis.x

		var forward_dot := velocity.dot(forward)
		var forward_tilt := clampf(forward_dot * deg_to_rad(run_pitch), deg_to_rad(-max_pitch), deg_to_rad(max_pitch))
		angles.x += forward_tilt

		var right_dot := velocity.dot(right)
		var side_tilt := clampf(right_dot * deg_to_rad(run_roll), deg_to_rad(-max_roll), deg_to_rad(max_roll))
		angles.z += side_tilt

	if enable_fall_kick:
		var fall_ratio = max(0.0, _fall_timer / fall_time)
		var fall_kick_amount = fall_ratio * _fall_value
		angles.x -= fall_kick_amount
		offset.y -= fall_kick_amount

	if enable_damage_kick:
		var damage_ratio = max(0.0, _damage_timer / damage_time)
		angles.x -= damage_ratio * _damage_pitch
		angles.z -= damage_ratio * _damage_roll

	if enable_weapon_kick:
		_weapon_kick_angles = _weapon_kick_angles.move_toward(Vector3.ZERO, weapon_decay * delta)
		angles += _weapon_kick_angles

	position = offset
	rotation = angles

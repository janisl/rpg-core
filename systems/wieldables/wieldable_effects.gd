class_name WieldableEffects
extends Node3D

@export_group("Idle sway")
@export var idle_sway_enabled := true
@export var idle_sway_frequency := 0.8
@export var idle_sway_amplitude := Vector2(0.003, 0.002)
@export var idle_sway_stiffness := 40.0
@export var idle_sway_damping := 10.0

@export_group("Look lag")
@export var look_lag_enabled := true
@export var look_lag_dividor := 20.0
@export_range(0, 90, 0.1, "radians_as_degrees") var look_lag_rot_max := deg_to_rad(30.0)
@export var look_lag_pos_scale := 0.1

@export_group("Strafe tilt")
@export var strafe_tilt_enabled := true
@export var strafe_tilt_scale := 0.3
@export_range(0, 90, 0.1, "radians_as_degrees") var strafe_tilt_max := 0.08
@export var strafe_tilt_stiffness := 80.0
@export var strafe_tilt_damping := 10.0

@export_group("Weapon bob")
@export var bob_enabled := true
@export var bob_amplitude := Vector2(0.02, 0.012)
@export var bob_max_speed := 10.0
@export var bob_stiffness := 60.0
@export var bob_damping := 10.0

@export_group("Recoil")
@export var recoil_enabled := true
@export var recoil_stiffness := 200.0
@export var recoil_damping := 11.0
@export var recoil_model_max := 0.15
@export_range(0, 90, 0.1, "radians_as_degrees") var recoil_pitch_max := 0.4

@export_group("Vertical lag")
@export var vertical_lag_enabled := true
@export var vertical_lag_stiffness := 80.0
@export var vertical_lag_damping := 12.0
@export var vertical_lag_dead_zome := 0.05
@export var vertical_lag_max := 0.03
@export var vertical_lag_vel_max := 10.0

var _idle_time := 0.0
var _idle_x := 0.0
var _idle_y := 0.0
var _idle_x_vel := 0.0
var _idle_y_vel := 0.0

var _prev_camera_rotation := Vector3.ZERO
var _cam_rot_rate := Vector3.ZERO

var _strafe_tilt := 0.0
var _strafe_tilt_vel := 0.0

var _bob_x := 0.0
var _bob_y := 0.0
var _bob_x_vel := 0.0
var _bob_y_vel := 0.0

var _recoil_z := 0.0
var _recoil_z_vel := 0.0
var _recoil_pitch := 0.0
var _recoil_pitch_vel := 0.0

var _vertical_lag_y := 0.0
var _vertical_lag_y_vel := 0.0
var _prev_camera_y := 0.0
var _vertical_lag_seeded := false

@onready var player: Player = $"../../../.."

func _process(delta: float) -> void:
	_apply_offsets(delta)


func reset_effects() -> void:
	_bob_x = 0
	_bob_y = 0
	_bob_x_vel = 0
	_bob_y_vel = 0

	_recoil_z = 0.0
	_recoil_z_vel = 0.0
	_recoil_pitch = 0.0
	_recoil_pitch_vel = 0.0


func add_model_recoil() -> void:
	if not recoil_enabled:
		return

	_recoil_z += player.wield_controller.wieldable_data.recoil_model_kickback
	_recoil_pitch += player.wield_controller.wieldable_data.recoil_model_rise


func _apply_offsets(delta: float) -> void:
	var model := player.wield_controller.first_person_model
	if not model:
		return

	var base_offset = _update_base_offset(delta)
	var idle_offset := _update_idle_sway(delta)
	var look_offset := _update_look_sway(delta)
	var bob_offset := _update_bob(delta)
	var recoil_offset := _update_recoil(delta)
	var vlag_offset := _update_vertical_lag(delta)

	var strafe_tilt = _update_strafe_tilt(delta)

	position = base_offset + idle_offset + look_offset + bob_offset + recoil_offset + vlag_offset
	rotation = Vector3(_recoil_pitch, 0.0, strafe_tilt)


func _update_base_offset(_delta: float) -> Vector3:
	return player.wield_controller.wieldable_data.first_person_position


func _update_idle_sway(delta: float) -> Vector3:
	if not idle_sway_enabled:
		return Vector3.ZERO

	_idle_time += delta

	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	var target_x := 0.0
	var target_y := 0.0

	if speed < 0.1:
		target_x = sin(_idle_time * idle_sway_frequency) * idle_sway_amplitude.x
		target_y = sin(_idle_time * idle_sway_frequency * 0.618) * idle_sway_amplitude.y

	var result_x := SpringUtil.apply(
			_idle_x,
			_idle_x_vel,
			target_x,
			idle_sway_stiffness,
			idle_sway_damping,
			delta
	)
	_idle_x = result_x.x
	_idle_x_vel = result_x.y

	var result_y := SpringUtil.apply(
			_idle_y,
			_idle_y_vel,
			target_y,
			idle_sway_stiffness,
			idle_sway_damping,
			delta
	)
	_idle_y = result_y.x
	_idle_y_vel = result_y.y

	var idle_offset := Vector3(_idle_x, _idle_y, 0.0)
	return idle_offset


func _update_look_sway(delta: float) -> Vector3:
	if not look_lag_enabled:
		return Vector3.ZERO

	var cam_rot := player.camera_effects.global_rotation

	var rot_delta := Vector3(
			angle_difference(_prev_camera_rotation.x, cam_rot.x),
			angle_difference(_prev_camera_rotation.y, cam_rot.y),
			0.0)
	_prev_camera_rotation = cam_rot

	rot_delta.x = clampf(rot_delta.x, -look_lag_rot_max, look_lag_rot_max)
	rot_delta.y = clampf(rot_delta.y, -look_lag_rot_max, look_lag_rot_max)
	rot_delta.z = 0.0

	var interp_speed := (1.0 / delta) / look_lag_dividor
	_cam_rot_rate = _cam_rot_rate.lerp(rot_delta, clampf(interp_speed * delta, 0.0, 1.0))

	var norm_pitch := _cam_rot_rate.x / look_lag_rot_max if look_lag_rot_max > 0.0 else 0.0
	var norm_yaw := _cam_rot_rate.y / look_lag_rot_max if look_lag_rot_max > 0.0 else 0.0
	var look_pos := Vector3(
			norm_yaw * look_lag_pos_scale,
			norm_pitch * -look_lag_pos_scale,
			0.0
	)

	return look_pos


func _update_strafe_tilt(delta: float) -> float:
	if not strafe_tilt_enabled:
		return 0.0

	var local_velocity := player.camera_effects.global_transform.basis.inverse() * player.velocity

	var xz := Vector2(local_velocity.x, local_velocity.z)
	var xz_speed := xz.length()

	var lateral_fraction: float = abs(xz.x) / xz_speed if xz_speed > 0.1 else 0.0

	var tilt_target = clampf(
			-local_velocity.x * lateral_fraction * strafe_tilt_scale,
			-strafe_tilt_max,
			strafe_tilt_max
	)

	var result = SpringUtil.apply(
			_strafe_tilt,
			_strafe_tilt_vel,
			tilt_target,
			strafe_tilt_stiffness,
			strafe_tilt_damping,
			delta
	)
	_strafe_tilt = result.x
	_strafe_tilt_vel = result.y

	return _strafe_tilt


func _update_bob(delta: float) -> Vector3:
	if not bob_enabled:
		return Vector3.ZERO

	var phase := player.camera_effects.step_timer
	var speed := Vector2(player.velocity.x, player.velocity.z).length()

	var target_x := 0.0
	var target_y := 0.0

	if speed >= 0.1:
		var speed_factor := clampf(speed / bob_max_speed, 0.0, 1.0)
		var angle := phase * TAU

		target_x = sin(angle) * bob_amplitude.x * speed_factor
		target_y = sin(angle * 2.0) * bob_amplitude.y * speed_factor

	var result_x := SpringUtil.apply(_bob_x, _bob_x_vel, target_x, bob_stiffness, bob_damping, delta)
	_bob_x = result_x.x
	_bob_x_vel = result_x.y

	var result_y := SpringUtil.apply(_bob_y, _bob_y_vel, target_y, bob_stiffness, bob_damping, delta)
	_bob_y = result_y.x
	_bob_y_vel = result_y.y

	return Vector3(_bob_x, _bob_y, 0.0)


func _update_recoil(delta: float) -> Vector3:
	if not recoil_enabled:
		_recoil_pitch = 0.0
		return Vector3.ZERO

	var result_z = SpringUtil.apply(
			_recoil_z,
			_recoil_z_vel,
			0.0,
			recoil_stiffness,
			recoil_damping,
			delta
	)
	_recoil_z = clampf(result_z.x, -recoil_model_max, recoil_model_max)
	_recoil_z_vel = result_z.y

	var result_pitch = SpringUtil.apply(
			_recoil_pitch,
			_recoil_pitch_vel,
			0.0,
			recoil_stiffness,
			recoil_damping,
			delta
	)
	_recoil_pitch = clampf(result_pitch.x, -recoil_pitch_max, recoil_pitch_max)
	_recoil_pitch_vel = result_pitch.y

	return Vector3(0.0, 0.0, _recoil_z)


func _update_vertical_lag(delta: float) -> Vector3:
	if not vertical_lag_enabled:
		return Vector3.ZERO

	var cam_y := player.camera_controller.global_position.y

	if not _vertical_lag_seeded:
		_prev_camera_y = cam_y
		_vertical_lag_seeded = true
		return Vector3.ZERO

	var cam_vel_y := (cam_y - _prev_camera_y) / delta
	_prev_camera_y = cam_y

	cam_vel_y = clampf(cam_vel_y, -vertical_lag_vel_max, vertical_lag_vel_max)
	if abs(cam_vel_y) < vertical_lag_dead_zome:
		cam_vel_y = 0.0

	var target_y := -cam_vel_y * player.wield_controller.wieldable_data.vertical_lag_amount
	var result = SpringUtil.apply(
			_vertical_lag_y,
			_vertical_lag_y_vel,
			target_y,
			vertical_lag_stiffness,
			vertical_lag_damping,
			delta
	)
	_vertical_lag_y = clampf(result.x, -vertical_lag_max, vertical_lag_max)
	_vertical_lag_y_vel = result.y

	return Vector3(0.0, _vertical_lag_y, 0.0)

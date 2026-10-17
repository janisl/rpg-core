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

@export_group("Recoil")
@export var enable_recoil := true
@export var recoil_stiffness := 80.0
@export var recoil_damping := 10.0
@export_range(0, 90, 0.1, "radians_as_degrees") var recoil_max := deg_to_rad(50.0)

@export_group("Screen shake")
@export var enable_screen_shake := true
@export var min_screen_shake := 0.05
@export var max_screen_shake := 0.5

@export_group("Headbob")
@export var enable_headbob := true
@export_range(0.0, 0.1, 0.001) var bob_pitch := 0.05
@export_range(0.0, 0.1, 0.001) var bob_roll := 0.025
@export_range(0.0, 0.04, 0.001) var bob_up := 0.005
@export_range(3.0, 8.0, 0.1) var bob_frequency := 6.0


var _fall_value := 0.0
var _fall_timer := 0.0

var _damage_pitch := 0.0
var _damage_roll := 0.0
var _damage_timer := 0.0

var _recoil_angles := Vector3.ZERO
var _recoil_velocity := Vector3.ZERO

var _screen_shake_tween: Tween

var step_timer := 0.0

var _swimmable_areas: Array[Area3D]


func _process(delta: float) -> void:
	_calcuate_view_offset(delta)


func add_fall_kick(fall_strength: float) -> void:
	_fall_value = deg_to_rad(fall_strength)
	_fall_timer = fall_time


func add_recoil(pitch: float, yaw: float, roll: float) -> void:
	_recoil_angles.x += pitch
	_recoil_angles.y += randf_range(-yaw, yaw)
	_recoil_angles.z += randf_range(-roll, roll)


func add_damage_kick(pitch: float, roll: float, source: Vector3) -> void:
	var forward := global_transform.basis.z
	var right := global_transform.basis.x
	var direction = global_position.direction_to(source)
	var forward_dot = direction.dot(forward)
	var right_dot = direction.dot(right)
	_damage_pitch = deg_to_rad(pitch) * forward_dot
	_damage_roll = deg_to_rad(roll) * right_dot
	_damage_timer = damage_time


func add_screen_shake(amount: float, seconds: float) -> void:
	if _screen_shake_tween:
		_screen_shake_tween.kill()

	_screen_shake_tween = create_tween()
	_screen_shake_tween.tween_method(_update_screen_shake.bind(amount), 0.0, 1.1, seconds).set_ease(Tween.EASE_OUT)


func _calcuate_view_offset(delta: float) -> void:
	if not player:
		return

	_fall_timer -= delta
	_damage_timer -= delta

	var velocity := player.velocity

	var speed = Vector2(velocity.x, velocity.z).length()
	if speed > 0.1 and player.is_on_floor():
		step_timer += delta * (speed / bob_frequency)
		step_timer = fmod(step_timer, 1.0)
	else:
		step_timer = 0.0
	var bob_sin = sin(step_timer * 2.0 * PI) * 0.5

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

	if enable_recoil:
		var d = min(delta, 0.05)
		for axis in 3:
			var result = SpringUtil.apply(
					_recoil_angles[axis],
					_recoil_velocity[axis],
					0.0,
					recoil_stiffness,
					recoil_damping,
					d)
			_recoil_angles[axis] = clampf(result.x, -recoil_max, recoil_max)
			_recoil_velocity[axis] = result.y

		angles += _recoil_angles

	if enable_headbob:
		var pitch_delta = bob_sin * deg_to_rad(bob_pitch) * speed
		angles.x -= pitch_delta

		var roll_delta = bob_sin * deg_to_rad(bob_roll) * speed
		angles.z -= roll_delta

		var bob_height = bob_sin * speed * bob_up
		offset.y += bob_height

	position = offset
	rotation = angles


func _update_screen_shake(alpha: float, amount: float) -> void:
	amount = remap(amount, 0.0, 1.1, min_screen_shake, max_screen_shake)
	var current_shake_amount = amount * (1.0 - alpha)
	h_offset = randf_range(-current_shake_amount, current_shake_amount)
	v_offset = randf_range(-current_shake_amount, current_shake_amount)


func _on_camera_area_entered(area: Area3D) -> void:
	if area.is_in_group("swimmable"):
		_swimmable_areas.append(area)
		GlobalManager.camera_underwater_effect = true


func _on_camera_area_exited(area: Area3D) -> void:
	if area.is_in_group("swimmable"):
		_swimmable_areas.erase(area)
		GlobalManager.camera_underwater_effect = _swimmable_areas.size() > 0

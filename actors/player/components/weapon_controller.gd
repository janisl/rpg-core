class_name WeaponController
extends Node

@export_group("References")
@export var player: Player
@export var camera: CameraEffects
@export var weapon_model_parent: Node3D
@export var weapon_state_chart: StateChart

@export_group("Weapon controller params")
@export_flags_3d_physics var hit_scan_collision_mask: int = 1

@export_group("Idle sway")
@export var idle_sway_enabled := true
@export var idle_sway_frequency := 0.8
@export var idle_sway_amplitude := Vector2(0.003, 0.002)
@export var idle_sway_stiffness := 40.0
@export var idle_sway_damping := 10.0

@export_group("Look lag")
@export var look_lag_enabled := true
@export var look_lag_dividor := 20.0
@export_range(0, 90, 0.1, "radians_as_degrees") var look_lag_rot_max := 30.0 * PI / 180.0
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

var current_weapon: Weapon
var current_weapon_model: Node3D
var animation_player: AnimationPlayer
var can_fire_next := true
var fire_rate_timer := 0.0

var base_weapon_position: Vector3

var idle_time := 0.0
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


func _process(delta: float) -> void:
	if fire_rate_timer > 0.0:
		fire_rate_timer -= delta
		if fire_rate_timer <= 0:
			can_fire_next = true

	_apply_offsets(delta)


func switch_weapon(data: WeaponData) -> void:
	current_weapon = data.weapon
	_spawn_weapon_model()
	weapon_state_chart.send_event("onIdle")
	print(current_weapon.weapon_name)


func has_ammo() -> bool:
	return Managers.weapon_manager.get_current_ammo() > 0


func can_fire() -> bool:
	return has_ammo() and can_fire_next


func fire_weapon() -> void:
	if not can_fire():
		return

	Managers.weapon_manager.use_ammo(Managers.weapon_manager.current_slot)
	animation_player.play("fire")
	print("Fired! Ammo: ", Managers.weapon_manager.get_current_ammo())

	can_fire_next = false
	fire_rate_timer = 1.0 / current_weapon.fire_rate

	if current_weapon.is_hit_scan:
		_perform_hit_scan()
	else:
		_spawn_projectile()


func _spawn_weapon_model() -> void:
	if current_weapon_model:
		current_weapon_model.queue_free()

	assert(current_weapon.weapon_scene, "Weapon has no scene")

	current_weapon_model = current_weapon.weapon_scene.instantiate()
	weapon_model_parent.add_child(current_weapon_model)
	current_weapon_model.position = current_weapon.weapon_position
	base_weapon_position = current_weapon.weapon_position
	animation_player = current_weapon_model.get_node("AnimationPlayer")
	_bob_x = 0
	_bob_y = 0
	_bob_x_vel = 0
	_bob_y_vel = 0


func _perform_hit_scan() -> void:
	assert(camera, "No camera assigned")

	var space_state := camera.get_world_3d().direct_space_state
	var from := camera.global_position
	var forward := -camera.global_transform.basis.z

	var accuracy_spread := (100.0 - current_weapon.accuracy) / 1000.0

	for i in current_weapon.pellet_count:
		var accuracy_x := randf_range(-accuracy_spread, accuracy_spread)
		var accuracy_y := randf_range(-accuracy_spread, accuracy_spread)
		var direction := forward + Vector3(accuracy_x, accuracy_y, 0) * camera.global_transform.basis

		if current_weapon.pellet_count > 1:
			var spread_x := randf_range(-current_weapon.spread_angle, current_weapon.spread_angle)
			var spread_y := randf_range(-current_weapon.spread_angle, current_weapon.spread_angle)
			direction += Vector3(spread_x, spread_y, 0) * camera.global_transform.basis

		var to := from + direction * current_weapon.range

		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = hit_scan_collision_mask
		var result := space_state.intersect_ray(query)

		if not result:
			return

		_spawn_impact_marker(result.position)
		_apply_damage_to_target(result.collider)


func _spawn_impact_marker(position: Vector3) -> void:
	var marker := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 0.1, 0.1)
	marker.mesh = box

	var material := StandardMaterial3D.new()
	material.albedo_color = Color.RED
	marker.set_surface_override_material(0, material)

	get_tree().current_scene.add_child(marker)
	marker.global_position = position

	get_tree().create_timer(2.0).timeout.connect(marker.queue_free)


func _spawn_projectile() -> void:
	assert(current_weapon.projectile_scene, "No projectile addigned")
	assert(camera, "No camera assigned")

	var projectile := current_weapon.projectile_scene.instantiate() as Projectile
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = camera.global_position

	var forward := -camera.global_transform.basis.z

	var accuracy_spread := (100.0 - current_weapon.accuracy) / 1000.0
	var accuracy_x := randf_range(-accuracy_spread, accuracy_spread)
	var accuracy_y := randf_range(-accuracy_spread, accuracy_spread)
	var direction := forward + Vector3(accuracy_x, accuracy_y, 0) * camera.global_transform.basis

	var velocity := direction * current_weapon.projectile_speed

	projectile.look_at(camera.global_position + direction, Vector3.UP)
	projectile.setup(player, velocity, current_weapon.damage)


func _apply_damage_to_target(target: Node3D) -> void:
	var health_component := target.get_node_or_null("HealthComponent") as HealthComponent

	if health_component:
		health_component.take_damage(current_weapon.damage, player)


func _apply_offsets(delta: float) -> void:
	var idle_offset := _update_idle_sway(delta)
	var look_offset := _update_look_sway(delta)
	var bob_offset := _update_bob(delta)

	var strafe_tilt = _update_strafe_tilt(delta)

	current_weapon_model.position = base_weapon_position + idle_offset + look_offset + bob_offset
	current_weapon_model.rotation = Vector3(0.0, 0.0, strafe_tilt)


func _update_idle_sway(delta: float) -> Vector3:
	if not idle_sway_enabled or not current_weapon_model:
		return Vector3.ZERO

	idle_time += delta

	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	var target_x := 0.0
	var target_y := 0.0

	if speed < 0.1:
		target_x = sin(idle_time * idle_sway_frequency) * idle_sway_amplitude.x
		target_y = sin(idle_time * idle_sway_frequency * 0.618) * idle_sway_amplitude.y

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
	if not look_lag_enabled or not camera:
		return Vector3.ZERO

	var cam_rot := camera.global_rotation

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
	if not strafe_tilt_enabled or not player or not camera:
		return 0.0

	var local_velocity := camera.global_transform.basis.inverse() * player.velocity

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
	if not bob_enabled or not current_weapon_model or not camera or not player:
		return Vector3.ZERO

	var phase := camera.step_timer
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

class_name WeaponController
extends Node

@export_group("References")
@export var player: Player
@export var camera: CameraEffects
@export var weapon_model_parent: Node3D
@export var weapon_state_chart: StateChart

@export_group("Weapon controller params")
@export_flags_3d_physics var hit_scan_collision_mask: int = 1
@export_flags_3d_render var weapon_mesh_layer := 1

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

var current_weapon: Weapon
var current_weapon_model: Node3D
var animation_player: AnimationPlayer
var _muzzle_flash: MuzzleFlash

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

var _recoil_z := 0.0
var _recoil_z_vel := 0.0
var _recoil_pitch := 0.0
var _recoil_pitch_vel := 0.0

var _vertical_lag_y := 0.0
var _vertical_lag_y_vel := 0.0
var _prev_camera_y := 0.0
var _vertical_lag_seeded := false


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

	camera.add_recoil(
		current_weapon.recoil_cam_pitch,
		current_weapon.recoil_cam_yaw,
		current_weapon.recoil_cam_roll)
	if recoil_enabled:
		_add_model_recoil()

	if _muzzle_flash:
		_muzzle_flash.flash(
				current_weapon.muzzle_light_color,
				current_weapon.muzzle_light_energy,
				current_weapon.muzzle_light_duration)

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

	var found := current_weapon_model.find_children("*", "MuzzleFlash", true, false)
	_muzzle_flash = found[0] if not found.is_empty() else null
	if _muzzle_flash:
		_muzzle_flash.configure(current_weapon)

	_apply_clip_and_fov_shader_to_view_model(current_weapon_model)

	_bob_x = 0
	_bob_y = 0
	_bob_x_vel = 0
	_bob_y_vel = 0

	_recoil_z = 0.0
	_recoil_z_vel = 0.0
	_recoil_pitch = 0.0
	_recoil_pitch_vel = 0.0


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

		var to := from + direction * current_weapon.hit_scan_range

		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = hit_scan_collision_mask
		var result := space_state.intersect_ray(query)

		if not result:
			return

		_spawn_impact_marker(result.position)
		_apply_damage_to_target(result.collider)

		if result.collider is RigidBody3D:
			result.collider.apply_impulse(-result.normal * 5.0 / result.collider.mass, result.position - result.collider.global_position)


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
	var recoil_offset := _update_recoil(delta)
	var vlag_offset := _update_vertical_lag(delta)

	var strafe_tilt = _update_strafe_tilt(delta)

	current_weapon_model.position = base_weapon_position + idle_offset + look_offset + bob_offset + recoil_offset + vlag_offset
	current_weapon_model.rotation = Vector3(_recoil_pitch, 0.0, strafe_tilt)


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


func _add_model_recoil() -> void:
	_recoil_z += current_weapon.recoil_model_kickback
	_recoil_pitch += current_weapon.recoil_model_rise


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
	if not vertical_lag_enabled or not player or not current_weapon_model:
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

	var target_y := -cam_vel_y * current_weapon.vertical_lag_amount
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


func _apply_clip_and_fov_shader_to_view_model(node3d : Node3D, fov_or_negative_for_unchanged = -1.0) -> void:
	var all_mesh_instances := node3d.find_children("*", "MeshInstance3D")
	if node3d is MeshInstance3D:
		all_mesh_instances.push_back(node3d)

	for mesh_instance in all_mesh_instances:
		var mesh = mesh_instance.mesh

		mesh_instance.layers = weapon_mesh_layer
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		for surface_idx in mesh.get_surface_count():
			var base_mat = mesh.surface_get_material(surface_idx)
			if not base_mat is BaseMaterial3D:
				continue

			var weapon_shader_material := ShaderMaterial.new()
			weapon_shader_material.shader = preload("res://shaders/weapon_clip_and_fov_shader.gdshader")
			weapon_shader_material.set_shader_parameter("texture_albedo", base_mat.albedo_texture)
			weapon_shader_material.set_shader_parameter("texture_metallic", base_mat.metallic_texture)
			weapon_shader_material.set_shader_parameter("texture_roughness", base_mat.roughness_texture)
			weapon_shader_material.set_shader_parameter("texture_normal", base_mat.normal_texture)
			weapon_shader_material.set_shader_parameter("albedo", base_mat.albedo_color)
			weapon_shader_material.set_shader_parameter("metallic", base_mat.metallic)
			weapon_shader_material.set_shader_parameter("specular", base_mat.metallic_specular)
			weapon_shader_material.set_shader_parameter("roughness", base_mat.roughness)
			weapon_shader_material.set_shader_parameter("viewmodel_fov", fov_or_negative_for_unchanged)
			var tex_channels = { 0: Vector4(1., 0., 0., 0.), 1: Vector4(0., 1., 0., 0.), 2: Vector4(0., 0., 1., 0.), 3: Vector4(1., 0., 0., 1.), 4: Vector4() }
			weapon_shader_material.set_shader_parameter("metallic_texture_channel", tex_channels[base_mat.metallic_texture_channel])
			mesh.surface_set_material(surface_idx, weapon_shader_material)

class_name Weapon
extends Item

var current_weapon_data: WeaponData
var player: Player
var camera: CameraEffects
var hit_scan_collision_mask: int
var weapon_manager: WeaponManager
var weapon_controller: WeaponController
var _muzzle_flash: MuzzleFlash
var animation_player: AnimationPlayer

var can_fire_next := true
var fire_rate_timer := 0.0

@onready var state_chart: StateChart = $StateChart


func _process(delta: float) -> void:
	if fire_rate_timer > 0.0:
		fire_rate_timer -= delta
		if fire_rate_timer <= 0:
			can_fire_next = true


func has_ammo() -> bool:
	return weapon_manager.get_current_ammo(current_weapon_data.ammo_type) > 0


func can_fire() -> bool:
	return has_ammo() and can_fire_next


func fire_weapon() -> void:
	if not can_fire():
		return

	Managers.weapon_manager.use_ammo(current_weapon_data.ammo_type)
	animation_player.play("fire")

	can_fire_next = false
	fire_rate_timer = 1.0 / current_weapon_data.fire_rate

	camera.add_recoil(
		current_weapon_data.recoil_cam_pitch,
		current_weapon_data.recoil_cam_yaw,
		current_weapon_data.recoil_cam_roll)
	if weapon_controller.recoil_enabled:
		weapon_controller._add_model_recoil()

	if _muzzle_flash:
		_muzzle_flash.flash()

	_perform_attack()


func _perform_attack() -> void:
	if current_weapon_data.is_hit_scan:
		_perform_hit_scan()
	else:
		_spawn_projectile()


func _perform_hit_scan() -> void:
	assert(camera, "No camera assigned")

	var space_state := camera.get_world_3d().direct_space_state
	var from := camera.global_position
	var forward := -camera.global_transform.basis.z

	var accuracy_spread := (100.0 - current_weapon_data.accuracy) / 1000.0

	for i in current_weapon_data.pellet_count:
		var accuracy_x := randf_range(-accuracy_spread, accuracy_spread)
		var accuracy_y := randf_range(-accuracy_spread, accuracy_spread)
		var direction := forward + Vector3(accuracy_x, accuracy_y, 0) * camera.global_transform.basis

		if current_weapon_data.pellet_count > 1:
			var spread_x := randf_range(-current_weapon_data.spread_angle, current_weapon_data.spread_angle)
			var spread_y := randf_range(-current_weapon_data.spread_angle, current_weapon_data.spread_angle)
			direction += Vector3(spread_x, spread_y, 0) * camera.global_transform.basis

		var to := from + direction * current_weapon_data.hit_scan_range

		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = hit_scan_collision_mask
		var result := space_state.intersect_ray(query)

		if not result:
			return

		_spawn_impact_marker(result.position)
		_apply_damage_to_target(result.collider)

		if result.collider is RigidBody3D:
			result.collider.apply_impulse(-result.normal * 5.0 / result.collider.mass, result.position - result.collider.global_position)


func _apply_damage_to_target(target: Node3D) -> void:
	var health_component := target.get_node_or_null("HealthComponent") as HealthComponent

	if health_component:
		health_component.take_damage(current_weapon_data.damage, player)


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
	assert(current_weapon_data.projectile_scene, "No projectile addigned")
	assert(camera, "No camera assigned")

	var projectile := current_weapon_data.projectile_scene.instantiate() as Projectile
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = camera.global_position

	var forward := -camera.global_transform.basis.z

	var accuracy_spread := (100.0 - current_weapon_data.accuracy) / 1000.0
	var accuracy_x := randf_range(-accuracy_spread, accuracy_spread)
	var accuracy_y := randf_range(-accuracy_spread, accuracy_spread)
	var direction := forward + Vector3(accuracy_x, accuracy_y, 0) * camera.global_transform.basis

	var velocity := direction * current_weapon_data.projectile_speed

	projectile.look_at(camera.global_position + direction, Vector3.UP)
	projectile.setup(player, velocity, current_weapon_data.damage)

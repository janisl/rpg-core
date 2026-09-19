class_name WeaponController
extends Node

@export_group("References")
@export var player: Player
@export var camera: Camera3D
@export var weapon_model_parent: Node3D
@export var weapon_state_chart: StateChart

@export_group("Weapon controller params")
@export_flags_3d_physics var hit_scan_collision_mask: int = 1

@export_group("Idle sway")
@export var idle_sway_frequency := 0.8
@export var idle_sway_amplitude := Vector2(0.003, 0.002)
@export var idle_sway_stiffness := 40.0
@export var idle_sway_damping := 10.0

var current_weapon: Weapon
var current_weapon_model: Node3D
var can_fire_next := true
var fire_rate_timer := 0.0

var base_weapon_position: Vector3

var idle_time := 0.0
var _idle_x := 0.0
var _idle_y := 0.0
var _idle_x_vel := 0.0
var _idle_y_vel := 0.0


func _process(delta: float) -> void:
	if fire_rate_timer > 0.0:
		fire_rate_timer -= delta
		if fire_rate_timer <= 0:
			can_fire_next = true

	_update_idle_sway(delta)


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


func _update_idle_sway(delta: float) -> void:
	if not current_weapon_model:
		return

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
	current_weapon_model.position = base_weapon_position + idle_offset

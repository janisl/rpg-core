class_name HitScanWeapon
extends Weapon

const BULLET_TRACER = preload("uid://lbvs8vldbgts")

@export_flags_3d_physics var hit_scan_collision_mask: int = 1


func _perform_attack(from: Vector3, fire_direction: Vector3) -> void:
	var space_state := get_world_3d().direct_space_state

	EffectsManager.spawn_light_flash(from, _weapon_data.light_color, _weapon_data.light_energy, _weapon_data.light_duration)

	var accuracy_spread := _get_accuracy_spread()
	var pellet_count := _get_pellet_count()

	for i in pellet_count:
		var direction := fire_direction + _get_spread_delta(fire_direction, accuracy_spread)

		if pellet_count > 1:
			direction += _get_spread_delta(fire_direction, _weapon_data.spread_angle * _get_spread_multiplier())

		var to := from + direction * _weapon_data.weapon_range

		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = hit_scan_collision_mask
		query.exclude = [ _item_owner.get_rid() ]
		var result := space_state.intersect_ray(query)

		if randf() < _weapon_data.bullet_tracer_chance:
			_spawn_tracer(from, result.position if result else to)
		if not result:
			continue

		_spawn_impact_effects(result)
		_apply_damage_to_target(result, direction)

		if result.collider is RigidBody3D:
			result.collider.apply_impulse(-result.normal * 5.0 / result.collider.mass, result.position - result.collider.global_position)


func _apply_damage_to_target(result: Dictionary, direction: Vector3) -> void:
	var health_attribute := result.collider.get_node_or_null("HealthAttribute") as HealthAttribute
	if not health_attribute:
		return

	var hit_info := HitInfo.new(_get_damage())
	hit_info.source_position = _item_owner.global_position
	hit_info.direction = direction
	hit_info.impact_position = result.position
	health_attribute.take_damage(hit_info)


func _spawn_impact_effects(result: Dictionary) -> void:
	EffectsManager.spawn_decal(_weapon_data.decal_scene, result.position, result.normal, result.collider, _item_owner.global_basis)

	if _weapon_data.impact_scene:
		var spawned_impact_scene := _weapon_data.impact_scene.instantiate()
		get_tree().current_scene.add_child(spawned_impact_scene)
		spawned_impact_scene.global_position = result.position


func _spawn_tracer(from: Vector3, target_position: Vector3) -> void:
	var bullet_dir := from.direction_to(target_position)
	var start_pos := from + bullet_dir * 0.25
	if start_pos.distance_to(target_position) > 3.0:
		var tracer := BULLET_TRACER.instantiate() as BulletTracer
		_item_owner.add_sibling(tracer)
		tracer.global_position = start_pos
		tracer.target_pos = target_position
		tracer.look_at(target_position)

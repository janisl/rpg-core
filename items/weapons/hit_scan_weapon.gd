class_name HitScanWeapon
extends Weapon

@export_flags_3d_physics var hit_scan_collision_mask: int = 1


func _perform_attack() -> void:
	_perform_hit_scan()


func _perform_hit_scan() -> void:
	var space_state := _item_owner.get_world_3d().direct_space_state

	var accuracy_spread := (100.0 - _weapon_data.accuracy) / 1000.0

	for i in _weapon_data.pellet_count:
		var direction := _forward_direction + _get_spread_delta(accuracy_spread)

		if _weapon_data.pellet_count > 1:
			direction += _get_spread_delta(_weapon_data.spread_angle)

		var to := _from_position + direction * _weapon_data.hit_scan_range

		var query := PhysicsRayQueryParameters3D.create(_from_position, to)
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
		health_component.take_damage(_weapon_data.damage, _item_owner)


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

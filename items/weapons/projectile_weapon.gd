class_name ProjectileWeapon
extends Weapon


func _perform_attack() -> void:
	_spawn_projectile()


func _spawn_projectile() -> void:
	assert(current_weapon_data.projectile_scene, "No projectile addigned")

	var projectile := current_weapon_data.projectile_scene.instantiate() as Projectile
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = _get_from_position()

	var forward := _get_forward_direction()

	var accuracy_spread := (100.0 - current_weapon_data.accuracy) / 1000.0
	var direction := forward + _get_spread_delta(accuracy_spread)

	var velocity := direction * current_weapon_data.projectile_speed

	projectile.look_at(projectile.global_position + direction, Vector3.UP)
	projectile.setup(item_owner, velocity, current_weapon_data.damage)

class_name ProjectileWeapon
extends Weapon


func _perform_attack() -> void:
	_spawn_projectile()


func _spawn_projectile() -> void:
	assert(_weapon_data.projectile_scene, "No projectile addigned")

	var projectile := _weapon_data.projectile_scene.instantiate() as Projectile
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = _from_position

	var accuracy_spread := (100.0 - _weapon_data.accuracy) / 1000.0
	var direction := _forward_direction + _get_spread_delta(accuracy_spread)

	var velocity := direction * _weapon_data.projectile_speed

	projectile.look_at(projectile.global_position + direction, Vector3.UP)
	projectile.setup(_item_owner, velocity, _weapon_data.damage)

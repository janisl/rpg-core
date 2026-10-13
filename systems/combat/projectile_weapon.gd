class_name ProjectileWeapon
extends Weapon


func _perform_attack(from: Vector3, fire_direction: Vector3) -> void:
	var projectile_scene := _get_projectile_scene()
	assert(projectile_scene, "No projectile addigned")

	var projectile := projectile_scene.instantiate() as Projectile
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = from

	var accuracy_spread := _get_accuracy_spread()
	var direction := fire_direction + _get_spread_delta(fire_direction, accuracy_spread)

	var velocity := direction * _weapon_data.projectile_speed

	projectile.look_at(projectile.global_position + direction, Vector3.UP)
	projectile.setup(_item_owner, velocity, _get_damage())

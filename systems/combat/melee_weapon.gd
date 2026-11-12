class_name MeleeWeapon
extends HitScanWeapon


func _perform_attack(from: Vector3, fire_direction: Vector3) -> void:
	_play_attack_sound(from)
	var _direction_basis := Basis.looking_at(fire_direction)

	for i in _weapon_data.melee_rays:
		var angle := -_weapon_data.melee_range / 2.0 + _weapon_data.melee_range / (_weapon_data.melee_rays - 1)
		var direction := fire_direction.rotated(_direction_basis.y, angle)

		_cast_ray(from, direction)


func _has_ammo() -> bool:
	return true


func _consume_ammo() -> void:
	pass

class_name ThrowableWeapon
extends ProjectileWeapon


func _has_ammo() -> bool:
	if not _owner_inventory:
		return true
	return _owner_inventory.get_available_amount(_weapon_data)


func _consume_ammo() -> void:
	if not _owner_inventory:
		return
	_owner_inventory.remove_item(_weapon_data)


func _attack_finished() -> void:
	if not _has_ammo():
		_emit_unequipped()
		return

	state_chart.send_event("onEquipping")

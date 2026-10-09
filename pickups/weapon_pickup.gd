class_name WeaponPickup
extends BasePickup

@export var weapon_resource: WeaponData


func _can_pickup(player: Player) -> bool:
	var weapon_slot := player.inventory.find_by_type(weapon_resource)
	if not weapon_slot or weapon_resource.ammo_types.is_empty():
		return not weapon_slot

	var ammo_type := weapon_resource.ammo_types[0]
	var ammo_slot := player.inventory.find_by_type(ammo_type)
	return not ammo_slot or ammo_slot.amount < ammo_type.max_stack


func _apply_pickup(player: Player) -> void:
	var weapon_slot := player.inventory.find_by_type(weapon_resource)

	if weapon_slot:
		if not weapon_resource.ammo_types.is_empty():
			player.inventory.add_item(weapon_resource.ammo_types[0], weapon_resource.magazine_size)
	else:
		Managers.weapon_manager.unlock_weapon(weapon_resource)
		Managers.weapon_manager.switch_to_weapon(weapon_resource)

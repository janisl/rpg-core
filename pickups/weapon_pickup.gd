class_name WeaponPickup
extends BasePickup

@export var weapon_resource: Weapon


func _can_pickup(player: Player) -> bool:
	var weapon_slot := player.inventory.find_by_type(weapon_resource)
	var ammo_slot := player.inventory.find_by_type(weapon_resource.ammo_type)
	return not weapon_slot or not ammo_slot or ammo_slot.amount < weapon_resource.max_ammo


func _apply_pickup(player: Player) -> void:
	var weapon_slot := player.inventory.find_by_type(weapon_resource)

	if weapon_slot:
		player.inventory.add_item(weapon_resource.ammo_type, weapon_resource.max_ammo)
	else:
		Managers.weapon_manager.unlock_weapon(weapon_resource)
		Managers.weapon_manager.switch_to_weapon(weapon_resource)

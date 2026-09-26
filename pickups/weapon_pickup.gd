class_name WeaponPickup
extends BasePickup

@export var weapon_resource: Weapon


func _can_pickup(player: Player) -> bool:
	var item_slot := player.inventory.find_by_type(weapon_resource)
	return not item_slot or item_slot.metadata.ammo < weapon_resource.max_ammo


func _apply_pickup(player: Player) -> void:
	var item_slot := player.inventory.find_by_type(weapon_resource)

	if item_slot:
		item_slot.metadata.ammo = weapon_resource.max_ammo
		print("Ammo refilled: ", weapon_resource.display_name)
	else:
		Managers.weapon_manager.unlock_weapon(weapon_resource)
		Managers.weapon_manager.switch_to_weapon(weapon_resource)
		print("Unlocked: ", weapon_resource.display_name)

class_name WeaponPickup
extends BasePickup

@export var weapon_resource: Weapon


func _can_pickup(_player: Player) -> bool:
	var weapon_data := Managers.weapon_manager.get_weapon_data(weapon_resource)
	return not weapon_data.unlocked or weapon_data.ammo < weapon_resource.max_ammo


func _apply_pickup(player: Player) -> void:
	var weapon_data := Managers.weapon_manager.get_weapon_data(weapon_resource)

	if weapon_data.unlocked:
		weapon_data.ammo = weapon_resource.max_ammo
		print("Ammo refilled: ", weapon_resource.display_name)
	else:
		Managers.weapon_manager.unlock_weapon(weapon_resource)
		Managers.weapon_manager.switch_to_weapon(weapon_resource)
		player.inventory.add_item(weapon_resource)
		print("Unlocked: ", weapon_resource.display_name)

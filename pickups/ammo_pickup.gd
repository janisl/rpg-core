class_name AmmoPickup
extends BasePickup

@export var weapon_slot := 1
@export var ammount := 10


func _can_pickup(_player: Player) -> bool:
	if weapon_slot not in Managers.weapon_manager.weapons:
		return false

	var weapon_data := Managers.weapon_manager.weapons[weapon_slot]
	return weapon_data.unlocked and weapon_data.ammo < weapon_data.weapon.max_ammo


func _apply_pickup(_player: Player) -> void:
	var weapon_data = Managers.weapon_manager.weapons[weapon_slot]

	var ammo_to_add: int = min(ammount, weapon_data.weapon.max_ammo - weapon_data.ammo)
	weapon_data.ammo += ammo_to_add
	print("Picked up: ", ammo_to_add, " ammo for ", weapon_data.weapon.display_name)

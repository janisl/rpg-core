class_name AmmoPickup
extends BasePickup

@export var weapon_slot := 1
@export var ammount := 10


func _can_pickup(player: Player) -> bool:
	var item_slot := player.inventory.slots[weapon_slot - 1]
	if not item_slot:
		return false

	return item_slot.metadata.ammo < item_slot.item.max_ammo


func _apply_pickup(player: Player) -> void:
	var item_slot := player.inventory.slots[weapon_slot - 1]

	var ammo_to_add: int = min(ammount, item_slot.item.max_ammo - item_slot.metadata.ammo)
	item_slot.metadata.ammo += ammo_to_add
	print("Picked up: ", ammo_to_add, " ammo for ", item_slot.item.display_name)

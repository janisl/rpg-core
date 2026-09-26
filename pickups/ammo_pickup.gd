class_name AmmoPickup
extends BasePickup

@export var ammo_type: Item
@export var ammount := 10


func _can_pickup(player: Player) -> bool:
	var item_slot := player.inventory.find_by_type(ammo_type)
	if not item_slot:
		return true

	return item_slot.amount < ammo_type.max_stack


func _apply_pickup(player: Player) -> void:
	var not_added = player.inventory.add_item(ammo_type, ammount)

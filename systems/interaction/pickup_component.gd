extends InteractionComponent
class_name PickupComponent

@export var item_stack : ItemStack


func interact(player: Player):
	if !is_disabled:
		pick_up(player)


func pick_up(player: Player):
	player.inventory.add_stack(item_stack)
	print("Picked up " + tr(item_stack.item.display_name))
	was_interacted_with.emit()
	get_parent().queue_free()

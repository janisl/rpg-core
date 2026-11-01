extends InteractionComponent
class_name PickupComponent

@export var item_stack : ItemStack


func interact(player: Player):
	if !is_disabled:
		pick_up(player)


func pick_up(player: Player):
	player.inventory.add_stack(item_stack)
	print("Picked up " + tr(item_stack.item.display_name))
	AudioManager.play_sound_3d(item_stack.item.pickup_sound, get_parent().global_position)
	was_interacted_with.emit()
	get_parent().queue_free()


func save_state() -> Dictionary:
	var state := super()
	#TODO save if it was dropped
	#state[&"item_stack"] = item_stack
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	#TODO save if it was dropped
	#item_stack = state.get(&"item_stack", item_stack)

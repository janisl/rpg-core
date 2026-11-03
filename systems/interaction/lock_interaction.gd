class_name LockInteraction
extends InteractionComponent

@onready var door := get_parent() as InteractableDoor


func _ready() -> void:
	assert(door, "Parent must be a door")
	door.lock_state_updated.connect(_lock_state_updated)


func interact(player: Player) -> void:
	if door.is_open:
		EventBus.show_notification.emit("Can't lock an open door")
		return

	if _check_for_item(player, door.key):
		door.lock_unlock_switch()
		was_interacted_with.emit()
	elif door.is_locked:
		EventBus.show_notification.emit(door.key_hint)


func start_hold_check(player: Player) -> bool:
	if door.is_open:
		return false
	return _check_for_item(player, door.key)


func _lock_state_updated(lock_interaction_text: String) -> void:
	interaction_text = lock_interaction_text
	EventBus.interactable_changed.emit()


func _check_for_item(player: Player, item: ItemData) -> bool:
	var inventory := player.inventory
	if inventory.get_available_amount(item):
		if item is KeyData:
			if item.discard_after_use:
				inventory.remove_item(item)
		return true
	return false

class_name Inventory
extends Node

signal changed
signal stack_added(stack: ItemStack)
signal stack_updated(stack: ItemStack)
signal stack_removed(stack: ItemStack)

@export var slots: Array[ItemStack]


func _ready() -> void:
	add_to_group("persist_component")


func save_state() -> Dictionary:
	return {
		&"slots" : slots,
	}


func load_state(state: Dictionary) -> void:
	slots = state.get(&"slots", [])


func add_item(item: ItemData, amount := 1, metadata: Dictionary[String, Variant] = {}) -> ItemStack:
	if not item or amount <= 0:
		return null
	return add_stack(ItemStack.new(item, amount, metadata))


func add_stack(stack: ItemStack) -> ItemStack:
	if not stack or not stack.is_valid:
		return null

	for i in slots.size():
		if not _can_stack(i, stack):
			continue

		slots[i].amount += stack.amount
		slots[i].emit_changed()
		stack_updated.emit(slots[i])
		changed.emit()
		return slots[i]

	var new_stack := stack.duplicate_deep()
	slots.append(new_stack)
	stack_added.emit(new_stack)
	changed.emit()
	return new_stack


func remove_item(item: ItemData, amount := 1, exact: bool = true) -> bool:
	if not item or amount <= 0:
		return true

	for i in slots.size():
		var stack := slots[i]
		if stack.item != item:
			continue

		if exact and stack.amount < amount:
			return false

		var removed_amount := mini(stack.amount, amount)
		stack.amount -= removed_amount
		stack.emit_changed()
		if stack.is_valid:
			stack_updated.emit(stack)
		else:
			slots.erase(stack)
			stack_removed.emit(stack)

		changed.emit()
		return removed_amount == amount

	return false


func remove_stack(item_stack: ItemStack) -> void:
	if not item_stack in slots:
		return
	slots.erase(item_stack)
	stack_removed.emit(item_stack)
	changed.emit()


func get_available_amount(item: ItemData) -> int:
	for i in slots.size():
		if slots[i].item == item:
			return slots[i].amount
	return 0


func find_by_type(item: ItemData) -> ItemStack:
	for slot in slots:
		if slot.item == item:
			return slot
	return null


func use_item(item_stack: ItemStack) -> void:
	if not item_stack.item.has_method("use"):
		return
	if not item_stack.item.use(get_parent(), item_stack):
		return
	if item_stack.item is ConsumableItem:
		remove_item(item_stack.item)


func take_all_items(target_inventory: Inventory) -> void:
	var taken := slots.duplicate()
	slots.clear()
	for slot in taken:
		target_inventory.add_stack(slot)
		stack_removed.emit(slot)
	changed.emit()


func _can_stack(index: int, stack: ItemStack) -> bool:
	var existing := slots[index]
	return stack.item.is_stacable and existing.item == stack.item and existing.metadata.recursive_equal(stack.metadata, 10)

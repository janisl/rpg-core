class_name Inventory
extends Node

signal changed

@export var slots: Array[ItemStack]


func add_item(item: ItemData, amount := 1, metadata: Dictionary[String, Variant] = {}):
	if not item or amount <= 0:
		return
	add_stack(ItemStack.new(item, amount, metadata))


func add_stack(stack: ItemStack):
	if not stack or not stack.is_valid:
		return

	for i in slots.size():
		if _is_empty(i):
			continue
		if not _can_stack(i, stack):
			continue

		slots[i].amount += stack.amount
		slots[i].emit_changed()
		changed.emit()
		return

	slots.append(stack)
	changed.emit()


func remove_item(item: ItemData, amount := 1, exact: bool = true) -> bool:
	if not item or amount <= 0:
		return true

	if exact:
		var available := get_available_amount(item)
		if available < amount:
			return false

	var remaining := amount

	for i in slots.size():
		if remaining == 0:
			break
		if _is_empty(i):
			continue
		var stack = slots[i]
		if stack.item != item:
			continue

		var removed_amount := mini(stack.amount, remaining)
		stack.amount -= removed_amount
		remaining -= removed_amount
		if not stack.is_valid:
			slots.erase(i)
		stack.emit_changed()

	changed.emit()
	return remaining == 0


func get_available_amount(item) -> int:
	var available := 0
	for i in slots.size():
		if _is_empty(i):
			continue
		var stack = slots[i]
		if stack.item != item:
			continue

		available += stack.amount

	return available


func find_by_type(item: ItemData) -> ItemStack:
	for slot in slots:
		if slot and slot.is_valid and slot.item == item:
			return slot
	return null


func _is_empty(index: int) -> bool:
	return slots[index] == null or not slots[index].is_valid


func _can_stack(index: int, stack: ItemStack) -> bool:
	var existing := slots[index]
	return existing.item == stack.item and existing.metadata.recursive_equal(stack.metadata, 10)

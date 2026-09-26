class_name Inventory
extends Node

signal changed

@export var slots: Array[ItemStack]


func add_item(item: Item, amount := 1, metadata: Dictionary[String, Variant] = {}) -> int:
	if not item or amount <= 0:
		return amount
	return add_stack(ItemStack.new(item, amount, metadata))


func add_stack(stack: ItemStack) -> int:
	if not stack or not stack.is_valid:
		return 0;

	var remaining := stack.amount
	for i in slots.size():
		if remaining == 0:
			break
		if _is_empty(i):
			continue
		if not _can_stack(i, stack):
			continue

		var space := _get_space(i, stack.item)
		var added_amount := mini(space, remaining)
		slots[i].amount += added_amount
		remaining -= added_amount

	for i in slots.size():
		if remaining == 0:
			break
		if not _is_empty(i):
			continue
		if not _can_accept(i, stack):
			continue

		var space := _get_space(i, stack.item)
		var added_amount := mini(space, remaining)
		slots[i] = ItemStack.new(stack.item, added_amount, stack.metadata)
		remaining -= added_amount

	changed.emit()
	return remaining


func _is_empty(index: int) -> bool:
	return slots[index] == null or not slots[index].is_valid


func _can_stack(index: int, stack: ItemStack) -> bool:
	var existing := slots[index]
	return existing.item == stack.item and existing.metadata.recursive_equal(stack.metadata, 10)


func _can_accept(_index: int, _stack: ItemStack) -> bool:
	return true


func _get_space(_index: int, item: Item) -> int:
	return item.max_stack

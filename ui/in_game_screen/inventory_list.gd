class_name InventoryList
extends ScrollContainer

const ITEM_SLOT_CONTROL = preload("uid://d3nmme6bfak14")

signal item_selected(item_stack: ItemStack)
signal item_clicked(item_stack: ItemStack)

@onready var slots_container: VBoxContainer = %SlotsContainer

var _inventory: Inventory
var _slot_controls: Dictionary[ItemStack, ItemSlotControl] = {}


func connect_to_inventory(inventory: Inventory) -> void:
	if _inventory:
		_inventory.stack_added.disconnect(_on_stack_added)
		_inventory.stack_removed.disconnect(_on_stack_removed)
	_inventory = inventory
	_inventory.stack_added.connect(_on_stack_added)
	_inventory.stack_removed.connect(_on_stack_removed)
	_recreate_slots()


func _recreate_slots() -> void:
	_clear()
	for stack in _inventory.slots:
		if stack and stack.is_valid:
			_add_slot(stack)


func _clear() -> void:
	for c in slots_container.get_children():
		c.queue_free()
	_slot_controls.clear()


func _add_slot(stack: ItemStack) -> void:
	if _slot_controls.has(stack):
		return
	var slot := ITEM_SLOT_CONTROL.instantiate() as ItemSlotControl
	var index := _sorted_index(stack)
	slots_container.add_child(slot)
	slots_container.move_child(slot, index)
	slot.init(stack)
	slot.mouse_entered.connect(_on_item_selected.bind(stack))
	slot.clicked.connect(_on_item_clicked)
	_slot_controls[stack] = slot


func _sorted_index(stack: ItemStack) -> int:
	var key := _sort_key(stack)
	for child in slots_container.get_children():
		var other := child as ItemSlotControl
		if other.is_queued_for_deletion() or not other.stack:
			continue
		if _sort_key(other.stack) > key:
			return child.get_index()
	return slots_container.get_child_count()


func _sort_key(stack: ItemStack) -> String:
	return tr(stack.item.display_name).to_lower()


func _on_stack_added(stack: ItemStack) -> void:
	_add_slot(stack)


func _on_stack_removed(stack: ItemStack) -> void:
	var slot: ItemSlotControl = _slot_controls.get(stack)
	_slot_controls.erase(stack)
	if is_instance_valid(slot) and not slot.is_queued_for_deletion():
		slot.queue_free()


func _on_item_selected(item_stack: ItemStack) -> void:
	item_selected.emit(item_stack)


func _on_item_clicked(item_stack: ItemStack) -> void:
	item_clicked.emit(item_stack)

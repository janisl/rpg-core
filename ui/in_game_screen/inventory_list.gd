class_name InventoryList
extends ScrollContainer

const ITEM_SLOT_CONTROL = preload("uid://d3nmme6bfak14")

signal item_selected(item: ItemStack)

@onready var slots_container: VBoxContainer = %SlotsContainer

var _inventory: Inventory


func connect_to_inventory(inventory: Inventory) -> void:
	_inventory = inventory


func recreate_slots() -> void:
	clear()
	for i in _inventory.slots.size():
		var slot := ITEM_SLOT_CONTROL.instantiate() as ItemSlotControl
		slots_container.add_child(slot)
		slot.init(_inventory.slots[i])
		slot.mouse_entered.connect(_on_item_selected.bind(_inventory.slots[i]))


func clear() -> void:
	for c in slots_container.get_children():
		c.queue_free()


func _on_item_selected(item: ItemStack) -> void:
	item_selected.emit(item)

class_name InventoryList
extends ScrollContainer

const ITEM_SLOT_CONTROL = preload("uid://d3nmme6bfak14")

signal item_selected(item_stack: ItemStack)
signal item_clicked(item_stack: ItemStack)

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
		slot.clicked.connect(_on_item_clicked)


func clear() -> void:
	for c in slots_container.get_children():
		c.queue_free()


func _on_item_selected(item_stack: ItemStack) -> void:
	item_selected.emit(item_stack)


func _on_item_clicked(item_stack: ItemStack) -> void:
	item_clicked.emit(item_stack)

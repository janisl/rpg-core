class_name ItemSlotControl
extends ColorRect

var _inventory: Inventory
var _index: int

@onready var item_icon: TextureRect = $ItemIcon
@onready var amount_label: Label = $AmountLabel


func init(inventory: Inventory, index: int) -> void:
	_inventory = inventory
	_index = index
	_update_slot()
	_inventory.slot_changed.connect(_on_slot_changed)


func _on_slot_changed(index: int) -> void:
	if index != _index:
		return
	_update_slot()


func _update_slot() -> void:
	var stack := _inventory.slots[_index]
	if not stack or not stack.is_valid:
		item_icon.visible = false
		amount_label.visible = false
	else:
		item_icon.visible = true
		item_icon.texture = stack.item.icon
		if stack.amount == 1:
			amount_label.visible = false
		else:
			amount_label.visible = true
			amount_label.text = str(stack.amount)

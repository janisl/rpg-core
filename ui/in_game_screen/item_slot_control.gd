class_name ItemSlotControl
extends ColorRect

var _stack: ItemStack

@onready var item_icon: TextureRect = $ItemIcon
@onready var amount_label: Label = $AmountLabel


func init(stack: ItemStack) -> void:
	_stack = stack
	_update_slot()
	_stack.changed.connect(_on_slot_changed)


func _on_slot_changed() -> void:
	_update_slot()


func _update_slot() -> void:
	if not _stack or not _stack.is_valid:
		queue_free()
		return

	item_icon.visible = true
	item_icon.texture = _stack.item.icon
	if _stack.amount == 1:
		amount_label.visible = false
	else:
		amount_label.visible = true
		amount_label.text = str(_stack.amount)

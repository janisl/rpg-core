class_name ItemSlotControl
extends PanelContainer

var _stack: ItemStack

@onready var item_icon: TextureRect = %ItemIcon
@onready var name_label: Label = %NameLabel


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

	item_icon.texture = _stack.item.icon
	name_label.text = tr(_stack.item.display_name)
	if _stack.amount > 1:
		name_label.text += " (%d)" % _stack.amount

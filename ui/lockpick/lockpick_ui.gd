class_name LockpickUI
extends Control

@onready var label_amount_lockpicks: Label = $MarginContainer/PanelContainer/MarginContainer/HBoxContainer/AmountLockpicks
@onready var item_icon_texture: TextureRect = $MarginContainer/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/ItemIconTexture


func update(lockpick_item: ItemData, amount: int) -> void:
	item_icon_texture.texture = lockpick_item.icon
	label_amount_lockpicks.text = str(amount)

class_name InGameScreen
extends Control

const ITEM_SLOT_CONTROL = preload("uid://d3nmme6bfak14")

@onready var slots_container: VBoxContainer = %SlotsContainer
@onready var name_label: Label = %NameLabel
@onready var icon_rect: TextureRect = %IconRect
@onready var description_label: Label = %DescriptionLabel
@onready var equip_button: Button = %EquipButton
@onready var detailsl_container: ScrollContainer = $DetailslContainer

var _player: Player
var _selected_item: ItemStack


func _ready() -> void:
	detailsl_container.hide()


func connect_to_player(player: Player) -> void:
	_player = player


func show_screen() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_recreate_slots()


func hide_screen() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_clear()


func _clear() -> void:
	for c in slots_container.get_children():
		c.queue_free()


func _recreate_slots() -> void:
	_clear()
	for i in _player.inventory.slots.size():
		var slot := ITEM_SLOT_CONTROL.instantiate() as ItemSlotControl
		slots_container.add_child(slot)
		slot.init(_player.inventory.slots[i])
		slot.mouse_entered.connect(_on_item_selected.bind(_player.inventory.slots[i]))


func _on_item_selected(item: ItemStack) -> void:
	_selected_item = item
	name_label.text = tr(item.item.display_name)
	icon_rect.texture = item.item.icon
	description_label.text = tr(item.item.description)
	equip_button.visible = item.item is WieldableData
	detailsl_container.show()

class_name InGameScreen
extends Control

@onready var name_label: Label = %NameLabel
@onready var icon_rect: TextureRect = %IconRect
@onready var description_label: Label = %DescriptionLabel
@onready var equip_button: Button = %EquipButton
@onready var detailsl_container: ScrollContainer = $DetailslContainer
@onready var unequip_button: Button = %UnequipButton
@onready var use_button: Button = %UseButton
@onready var drop_button: Button = %DropButton
@onready var inventory_list: InventoryList = $InventoryList

var _player: Player
var _selected_item: ItemStack


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("inventory"):
		hide_screen()
		get_viewport().set_input_as_handled()


func connect_to_player(player: Player) -> void:
	_player = player
	inventory_list.connect_to_inventory(player.inventory)


func show_screen() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_selected_item = null
	detailsl_container.hide()
	inventory_list.recreate_slots()


func hide_screen() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	inventory_list.clear()


func _on_inventory_list_item_selected(item: ItemStack) -> void:
	_selected_item = item
	name_label.text = tr(item.item.display_name)
	icon_rect.texture = item.item.icon
	description_label.text = tr(item.item.description)
	equip_button.visible = item.item is WieldableData and _player.wield_controller.current_item_stack != item
	unequip_button.visible = item.item is WieldableData and _player.wield_controller.current_item_stack == item
	use_button.visible = item.item is ConsumableItem
	drop_button.visible = item.item.drop_stack_size > 0 and _player.wield_controller.current_item_stack != item
	detailsl_container.show()


func _on_equip_button_pressed() -> void:
	_player.wield_controller.switch_wieldable(_selected_item)
	hide_screen()


func _on_unequip_button_pressed() -> void:
	_player.wield_controller.switch_wieldable(null)
	hide_screen()


func _on_use_button_pressed() -> void:
	_player.inventory.use_item(_selected_item)
	if not _selected_item.is_valid:
		detailsl_container.hide()


func _on_drop_button_pressed() -> void:
	_player.drop_item(_selected_item)
	if not _selected_item.is_valid:
		detailsl_container.hide()

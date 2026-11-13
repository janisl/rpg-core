class_name ExternalInventory
extends Control

@onready var player_inventory_list: InventoryList = %PlayerInventoryList
@onready var loot_inventory_list: InventoryList = %LootInventoryList

var _player: Player
var _loot_inventory: Inventory


func _input(event: InputEvent) -> void:
	if visible && event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func initialize(player: Player, loot_inventory: Inventory) -> void:
	_player = player
	_loot_inventory = loot_inventory
	player_inventory_list.connect_to_inventory(player.inventory)
	loot_inventory_list.connect_to_inventory(loot_inventory)


func _close() -> void:
		hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_take_all_button_pressed() -> void:
	_loot_inventory.take_all_items(_player.inventory)
	_close()


func _on_loot_inventory_list_item_clicked(item_stack: ItemStack) -> void:
	_player.inventory.add_stack(item_stack)
	_loot_inventory.remove_stack(item_stack)


func _on_player_inventory_list_item_clicked(item_stack: ItemStack) -> void:
	_player.inventory.remove_stack(item_stack)
	_loot_inventory.add_stack(item_stack)

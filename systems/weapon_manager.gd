class_name WeaponManager
extends Node


@export var player: Player

var current_slot := 1


func _ready() -> void:
	for i in range(1, 10):
		var action_name = "weapon_" + str(i)
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var event = InputEventKey.new()
			event.keycode = KEY_1 + (i - 1)
			InputMap.action_add_event(action_name, event)

	initialize_starting_weapon.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	for i in range(0, 9):
		if event.is_action_pressed("weapon_" + str(i + 1)):
			switch_to_slot(i)


func initialize_starting_weapon() -> void:
	for slot in range(0, 9):
		if player.inventory.slots[slot] and player.inventory.slots[slot].item is Weapon:
			switch_to_slot(slot)
			return


func switch_to_slot(index: int) -> void:
	var item_stack := player.inventory.slots[index]
	current_slot = index
	player.weapon_controller.switch_weapon(item_stack)


func switch_to_weapon(weapon: Weapon) -> void:
	for slot in range(0, 9):
		if player.inventory.slots[slot] and player.inventory.slots[slot].item == weapon:
			switch_to_slot(slot)


func use_ammo(type: Item, amount: int = 1) -> void:
	var item_stack := player.inventory.find_by_type(type)
	if item_stack:
		item_stack.amount = max(0, item_stack.amount - amount)


func get_current_ammo(type: Item) -> int:
	var item_stack := player.inventory.find_by_type(type)
	return item_stack.amount if item_stack else 0


func unlock_weapon(weapon: Weapon) -> void:
	player.inventory.add_item(weapon)
	player.inventory.add_item(weapon.ammo_type, weapon.max_ammo)

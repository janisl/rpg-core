class_name WeaponManager
extends Node

signal current_slot_changed

var player: Player
var current_slot := -1


func _ready() -> void:
	for i in range(1, 10):
		var action_name = "weapon_" + str(i)
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var event = InputEventKey.new()
			event.keycode = KEY_1 + (i - 1)
			InputMap.action_add_event(action_name, event)

	EventBus.player_spawned.connect(_on_player_spawned)


func _on_player_spawned(p: Player) -> void:
	player = p
	initialize_starting_weapon.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	for i in range(0, 9):
		if event.is_action_pressed("weapon_" + str(i + 1)):
			switch_to_slot(i)


func initialize_starting_weapon() -> void:
	for slot in range(0, mini(9, player.inventory.slots.size())):
		if player.inventory.slots[slot] and player.inventory.slots[slot].item is WeaponData:
			switch_to_slot(slot)
			return


func switch_to_slot(index: int) -> void:
	var item_stack := player.inventory.slots[index]
	current_slot = index
	current_slot_changed.emit()
	player.wield_controller.switch_wieldable(item_stack)


func switch_to_weapon(weapon: WeaponData) -> void:
	for slot in range(0, 9):
		if player.inventory.slots[slot] and player.inventory.slots[slot].item == weapon:
			switch_to_slot(slot)

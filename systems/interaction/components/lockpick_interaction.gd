extends InteractionComponent
class_name LockpickInteraction

const LOCKPICK_UI = preload("uid://dl4u0yhv6h1m6")

signal lockpick_success

@export var lockpick_minigame: PackedScene
@export var required_lockpick_item: ItemData
@export var doors_to_unlock: Array[Door]

@export_subgroup("Hint messages")
@export var lockpick_item_hint := "LOCKPICK HINT Required"
@export var lockpick_item_breaks_hint := "LOCKPICK HINT Broke"
@export var lockpick_success_hint := "LOCKPICK HINT Success"

var _spawned_lockpick_game: LockpickMinigame
var _player: Player
var _lockpick_ui: LockpickUI


func _ready() -> void:
	_spawned_lockpick_game = lockpick_minigame.instantiate()

	if doors_to_unlock:
		for door in doors_to_unlock:
			door.lock_state_changed.connect(_on_door_lock_state_change)


func interact(player: Player) -> void:
	_player = player

	if not _get_lockpick_amount_in_inventory():
		if lockpick_item_hint:
			EventBus.show_notification.emit(lockpick_item_hint)
		return

	_lockpick_ui = UserInterface.show_in_game_screen(LOCKPICK_UI)

	if not _spawned_lockpick_game:
		_spawned_lockpick_game = lockpick_minigame.instantiate()
	_player.head.add_child(_spawned_lockpick_game)

	_spawned_lockpick_game.unlocked.connect(_on_lock_picked)
	_spawned_lockpick_game.cancelled.connect(_on_cancel)
	_spawned_lockpick_game.lockpick_broke.connect(_discard_lockpick)

	if attribute_check != AttributeCheck.NONE:
		var fetched_attribute: BaseAttribute = _player.player_attributes.get(attribute_to_check)
		_spawned_lockpick_game.pass_player_attribute(fetched_attribute)

	_lockpick_ui.update(required_lockpick_item, _get_lockpick_amount_in_inventory())


func _get_lockpick_amount_in_inventory() -> int:
	return _player.inventory.get_available_amount(required_lockpick_item)


func _on_lock_picked() -> void:
	if lockpick_success_hint:
		EventBus.show_notification.emit(tr(lockpick_success_hint))

	UserInterface.close_in_game_screen()

	if doors_to_unlock:
		for door in doors_to_unlock:
			door.unlock_door()

	lockpick_success.emit()
	_spawned_lockpick_game.queue_free()


func _on_cancel() -> void:
	_spawned_lockpick_game.queue_free()
	UserInterface.close_in_game_screen()


func _discard_lockpick() -> void:
	if _player.inventory.remove_item(required_lockpick_item):
		EventBus.show_notification.emit(tr(lockpick_item_breaks_hint))

	var lockpicks_left := _get_lockpick_amount_in_inventory()
	_lockpick_ui.update(required_lockpick_item, lockpicks_left)

	if lockpicks_left <= 0:
		_spawned_lockpick_game.exit_game()
	else:
		_spawned_lockpick_game.grab_new_lockpick()


func _on_door_lock_state_change(is_locked: bool) -> void:
	is_disabled = not is_locked
	EventBus.interactable_changed.emit()

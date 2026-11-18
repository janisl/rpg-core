@warning_ignore("missing_tool")
class_name Keypad
extends DynamicObject

const KEYPAD_UI = preload("uid://barugt8oxroqa")

signal correct_code_entered
signal object_state_updated(interaction_text: String)

@export_group("Keypad Settings")
@export var passcode: String
@export var interaction_text_when_locked : String = "INTERACT Enter code"
@export var interaction_text_when_unlocked : String = "INTERACT Access granted"

@export var doors_to_unlock: Array[Door]
@export var open_when_unlocked: bool

var _is_locked := true
var _player: Player
var _screen: KeypadUI


func _ready() -> void:
	super()
	object_state_updated.emit(interaction_text_when_locked)


func save_state() -> Dictionary:
	var state := super()
	state[&"is_locked"] = _is_locked
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	_is_locked = state.get(&"is_locked", false)


func interact(player: Player) -> void:
	if not _is_locked:
		return

	_player = player
	if _screen:
		_close()
	else:
		_open()


func _open() -> void:
	_screen = UserInterface.show_in_game_screen(KEYPAD_UI)
	_screen.passcode = passcode
	_screen.correct_code_entered.connect(_unlock_keypad)


func _close() -> void:
	UserInterface.close_in_game_screen()


func _unlock_keypad() -> void:
	_is_locked = false
	object_state_updated.emit(interaction_text_when_unlocked)
	correct_code_entered.emit()

	for door in doors_to_unlock:
		door.unlock_door()
		if open_when_unlocked:
			door.open_door(_player)

	_close()

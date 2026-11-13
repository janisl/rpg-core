@tool
class_name InteractableContainer
extends DynamicObject

const EXTERNAL_IVENTORY = preload("uid://dm6b1w6fv1h34")

signal object_state_updated(interaction_text: String)

@export_group("Container Settings")
@export var inventory: Inventory
@export var text_when_closed := "INTERACT Open"
@export var text_when_open := "INTERACT Close"

var _screen: Control


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return

	object_state_updated.emit(text_when_closed)
	EventBus.in_game_screen_closed.connect(_on_screen_closed)


func load_state(state: Dictionary) -> void:
	super(state)
	object_state_updated.emit(text_when_closed)


func interact(player: Player) -> void:
	if _screen:
		UserInterface.close_in_game_screen()
	else:
		_screen = UserInterface.show_in_game_screen(EXTERNAL_IVENTORY)
		_screen.initialize(player, inventory)


func _on_screen_closed(screen: Control) -> void:
	if _screen and screen == _screen:
		screen = null

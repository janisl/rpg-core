@tool
class_name InteractableContainer
extends DynamicObject

const EXTERNAL_IVENTORY = preload("uid://dm6b1w6fv1h34")

signal object_state_updated(interaction_text: String)
signal container_opened
signal container_closed

@export_group("Container Settings")
@export var inventory: Inventory
@export var text_when_closed := "INTERACT Open"
@export var text_when_open := "INTERACT Close"

@export_group("Animation Settings")
@export var uses_animation := false
@export var open_animation: String
@export var use_reverse_open_as_close_anim := false
@export var close_animation: String

var _screen: Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer


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
		_open(player)


func _on_screen_closed(screen: Control) -> void:
	if _screen and screen == _screen:
		_close()


func _open(player: Player) -> void:
	_screen = UserInterface.show_in_game_screen(EXTERNAL_IVENTORY)
	_screen.initialize(player, inventory)

	if uses_animation:
		animation_player.play(open_animation)

	object_state_updated.emit(text_when_open)
	container_opened.emit()


func _close() -> void:
	if uses_animation:
		if use_reverse_open_as_close_anim:
			animation_player.play_backwards(open_animation)
		else:
			animation_player.play(close_animation)

	object_state_updated.emit(text_when_closed)
	container_closed.emit()
	_screen = null

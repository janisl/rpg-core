@tool
class_name InteractableContainer
extends DynamicObject

signal object_state_updated(interaction_text: String)

@export_group("Container Settings")
@export var inventory: Inventory
@export var text_when_closed := "INTERACT Open"
@export var text_when_open := "INTERACT Close"


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return

	object_state_updated.emit(text_when_closed)


func load_state(state: Dictionary) -> void:
	super(state)
	object_state_updated.emit(text_when_closed)


func interact(player: Player) -> void:
	UserInterface.show_loot_inventory(player, inventory)

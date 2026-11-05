class_name DualInteraction
extends HoldInteraction

signal on_quick_press(player: Player)
signal on_hold_complete(player: Player)

@export var interaction_text_joiner: String = "INTERACT hold joiner"
@export var hold_node: Node

var press_interaction_text: String
var hold_interaction_text: String


func _ready() -> void:
	super()
	if parent_node.has_signal("lock_state_updated"):
		parent_node.lock_state_updated.connect(_lock_state_updated)


func save_state() -> Dictionary:
	var state := super()
	state[&"press_interaction_text"] = press_interaction_text
	state[&"hold_interaction_text"] = hold_interaction_text
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	press_interaction_text = state.get(&"press_interaction_text", press_interaction_text)
	hold_interaction_text = state.get(&"hold_interaction_text", hold_interaction_text)


func interact(player: Player) -> void:
	if hold_node and hold_node.has_method("start_hold_check"):
		if not hold_node.start_hold_check(player):
			parent_node.interact(player) 
			return

	super(player)


func _on_object_state_change(new_text: String) -> void:
	press_interaction_text = new_text
	_update_interaction_text()


func _lock_state_updated(new_text: String) -> void:
	hold_interaction_text = new_text
	_update_interaction_text()


func _update_interaction_text() -> void:
	interaction_text = tr(press_interaction_text) + tr(interaction_text_joiner) + tr(hold_interaction_text)
	EventBus.interactable_changed.emit()


func _complete() -> void:
	on_hold_complete.emit(_player)


func _hold_released() -> void:
	on_quick_press.emit(_player)

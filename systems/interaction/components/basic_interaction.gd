class_name BasicInteraction
extends InteractionComponent

@onready var parent_node: Node3D = get_parent()


func _ready() -> void:
	super()
	if parent_node.has_signal("object_state_updated"):
		parent_node.object_state_updated.connect(_on_object_state_change)


func save_state() -> Dictionary:
	var state := super()
	state[&"interaction_text"] = interaction_text
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	interaction_text = state.get(&"interaction_text", interaction_text)


func interact(player: Player) -> void:
	if parent_node.has_method("interact"):
		parent_node.interact(player)

	was_interacted_with.emit()


func _on_object_state_change(_interaction_text: String) -> void:
	interaction_text = _interaction_text
	EventBus.interactable_changed.emit()

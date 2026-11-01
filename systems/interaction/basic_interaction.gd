class_name BasicInteraction
extends InteractionComponent

@onready var parent_node: Node3D = get_parent()


func _ready() -> void:
	if parent_node.has_signal("object_state_updated"):
		parent_node.object_state_updated.connect(_on_object_state_change)


func interact(player: Player) -> void:
	if parent_node.has_method("interact"):
		parent_node.interact(player)

	was_interacted_with.emit()


func _on_object_state_change(_interaction_text: String) -> void:
	interaction_text = _interaction_text
	EventBus.interactable_changed.emit()

class_name InteractionComponent
extends Node3D

signal was_interacted_with()

@export var input_map_action := "interact"
@export var interaction_text : String
@export var is_disabled := false
@export var make_parent_interactable := true


func _ready() -> void:
	add_to_group("persist_component")
	if make_parent_interactable:
		get_parent().add_to_group("interactable")


@warning_ignore("unused_parameter")
func interact(player: Player) -> void:
	pass


func _emit_was_interacted_with() -> void:
	was_interacted_with.emit()


func save_state() -> Dictionary:
	return {
		&"is_disabled" : is_disabled,
	}


func load_state(state: Dictionary) -> void:
	is_disabled = state.get(&"is_disabled", false)

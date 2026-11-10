class_name InteractionComponent
extends Node3D

enum AttributeCheck { NONE, FAIL_MESSAGE, HIDE_INTERACTION }

@warning_ignore("unused_signal")
signal was_interacted_with()

@export var input_map_action := "interact"
@export var interaction_text : String
@export var is_disabled := false
@export var make_parent_interactable := true

@export_group("Attribute Checks")
@export var attribute_check := AttributeCheck.NONE
@export var attribute_to_check := BaseAttribute.AttributeType.NONE
@export var min_value_to_pass := 0.0
@export var message_on_pass: String
@export var message_on_fail: String


func _ready() -> void:
	add_to_group("persist_component")
	if make_parent_interactable:
		get_parent().add_to_group("interactable")


@warning_ignore("unused_parameter")
func interact(player: Player) -> void:
	pass


func save_state() -> Dictionary:
	return {
		&"is_disabled" : is_disabled,
	}


func load_state(state: Dictionary) -> void:
	is_disabled = state.get(&"is_disabled", false)


func check_attribute(player: Player) -> bool:
	if attribute_check == AttributeCheck.NONE:
		return true

	assert(attribute_to_check)
	var fetched_attribute: BaseAttribute = player.player_attributes.get(attribute_to_check)
	assert(fetched_attribute, "attribute (" + str(attribute_to_check) + ") was not found in player_attributes!")

	if fetched_attribute.value >= min_value_to_pass:
		if message_on_pass and attribute_check == AttributeCheck.FAIL_MESSAGE:
			EventBus.show_notification.emit(tr(message_on_pass))
		return true
	else:
		if message_on_fail and attribute_check == AttributeCheck.FAIL_MESSAGE:
			EventBus.show_notification.emit(tr(message_on_fail))
		return false


func update_disabled_state(_player: Player) -> void:
	pass

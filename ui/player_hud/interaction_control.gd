class_name InteractionControl
extends PanelContainer

@onready var key_label: Label = %KeyLabel
@onready var action_label: Label = %ActionLabel


func initialize(interaction: InteractionComponent) -> void:
	key_label.text = _get_action_key_string(interaction.input_map_action)
	action_label.text = tr(interaction.interaction_text)


func _get_action_key_string(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.as_text_physical_keycode()
	return ""

class_name InteractionControl
extends PanelContainer

var _hold_interaction: HoldInteraction

@onready var key_label: Label = %KeyLabel
@onready var action_label: Label = %ActionLabel
@onready var progress_wheel: ProgressWheel = %ProgressWheel
@onready var progress_container: Control = %ProgressContainer


func initialize(interaction: InteractionComponent) -> void:
	_hold_interaction = interaction as HoldInteraction
	set_prompt(interaction.interaction_text, interaction.input_map_action)


func set_prompt(interaction_text: String, input_map_action: String) -> void:
	key_label.text = _get_action_key_string(input_map_action)
	action_label.text = tr(interaction_text)
	progress_wheel.hide()
	progress_wheel.current_value = 0.0
	if _hold_interaction:
		_hold_interaction.hold_progress_changed.connect(_on_hold_progress_changed)
	else:
		progress_container.hide()


func _get_action_key_string(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return _key_event_to_text(event)
		if event is InputEventMouseButton:
			return "Mouse %d" % event.button_index
		if event is InputEventJoypadButton:
			return "Pad Button %d" % event.button_index
		if event is InputEventJoypadMotion:
			return "Pad Axis %d" % event.axis
	return ""


func _key_event_to_text(event: InputEventKey) -> String:
	if event.physical_keycode != KEY_NONE:
		return event.as_text_physical_keycode()
	if event.keycode != KEY_NONE:
		return event.as_text_keycode()
	return event.as_text_key_label()

func _on_hold_progress_changed() -> void:
	progress_wheel.visible = _hold_interaction.show_hold_progress
	progress_wheel.current_value = _hold_interaction.hold_progress

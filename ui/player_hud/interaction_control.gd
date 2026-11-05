class_name InteractionControl
extends PanelContainer

var _hold_interaction: HoldInteraction

@onready var key_label: Label = %KeyLabel
@onready var action_label: Label = %ActionLabel
@onready var progress_wheel: ProgressWheel = %ProgressWheel
@onready var progress_container: Control = %ProgressContainer


func initialize(interaction: InteractionComponent) -> void:
	key_label.text = _get_action_key_string(interaction.input_map_action)
	action_label.text = tr(interaction.interaction_text)
	_hold_interaction = interaction as HoldInteraction
	progress_wheel.hide()
	progress_wheel.current_value = 0.0
	if _hold_interaction:
		_hold_interaction.hold_progress_changed.connect(_on_hold_progress_changed)
	else:
		progress_container.hide()


func _get_action_key_string(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.as_text_physical_keycode()
	return ""


func _on_hold_progress_changed() -> void:
	progress_wheel.visible = _hold_interaction.show_hold_progress
	progress_wheel.current_value = _hold_interaction.hold_progress

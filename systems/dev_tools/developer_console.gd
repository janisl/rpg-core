extends CanvasLayer

signal developer_overlay_visibility_changed(is_visible: bool)

@onready var overlay_check_button: CheckButton = $InputBlocker/CenterContainer/PanelContainer/VBoxContainer/OverlayCheckButton

var _previous_mouse_mode: Input.MouseMode
var _was_paused_before_open := false


func _ready() -> void:
	overlay_check_button.toggled.connect(_on_overlay_check_button_toggled)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_console"):
		_set_console_visible(not visible)
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		_set_console_visible(false)
		get_viewport().set_input_as_handled()


func _set_console_visible(should_show: bool) -> void:
	if visible == should_show:
		return

	visible = should_show
	if visible:
		_previous_mouse_mode = Input.mouse_mode
		_was_paused_before_open = get_tree().paused
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true
		overlay_check_button.grab_focus()
	else:
		overlay_check_button.release_focus()
		Input.mouse_mode = _previous_mouse_mode
		get_tree().paused = _was_paused_before_open


func _on_overlay_check_button_toggled(is_visible: bool) -> void:
	developer_overlay_visibility_changed.emit(is_visible)

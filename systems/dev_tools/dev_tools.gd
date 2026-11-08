extends Node

@onready var debug_line: Node = $DebugLine
@onready var developer_overlay: CanvasLayer = $DeveloperOverlay
@onready var developer_console: CanvasLayer = $DeveloperConsole

var show_attention_points := false


func _ready() -> void:
	developer_console.developer_overlay_visibility_changed.connect(_on_developer_overlay_visibility_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_exit"):
		get_tree().quit()

	if event.is_action_pressed("dev_reload"):
		get_tree().reload_current_scene()


func _on_developer_overlay_visibility_changed(is_visible: bool) -> void:
	developer_overlay.visible = is_visible

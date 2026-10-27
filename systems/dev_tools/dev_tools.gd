extends Node

@onready var debug_line: Node = $DebugLine
@onready var developer_overlay: CanvasLayer = $DeveloperOverlay
@onready var developer_console: CanvasLayer = $DeveloperConsole


func _ready() -> void:
	developer_console.developer_overlay_visibility_changed.connect(_on_developer_overlay_visibility_changed)


func _on_developer_overlay_visibility_changed(is_visible: bool) -> void:
	developer_overlay.visible = is_visible

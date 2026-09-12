extends CanvasLayer

@onready var water_ripple_overlay: TextureRect = $WaterRippleOverlay


func _ready() -> void:
	GlobalManager.camera_underwater_effect_changed.connect(_on_camera_underwater_effect_changed)


func _on_camera_underwater_effect_changed() -> void:
	water_ripple_overlay.visible = GlobalManager.camera_underwater_effect

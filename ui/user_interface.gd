extends CanvasLayer

@onready var water_ripple_overlay: TextureRect = $WaterRippleOverlay
@onready var in_game_screen: InGameScreen = $InGameScreen


func _ready() -> void:
	GlobalManager.camera_underwater_effect_changed.connect(_on_camera_underwater_effect_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if in_game_screen.visible:
			in_game_screen.hide_screen()
		else:
			in_game_screen.show_screen()


func _on_camera_underwater_effect_changed() -> void:
	water_ripple_overlay.visible = GlobalManager.camera_underwater_effect

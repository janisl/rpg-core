extends CanvasLayer

@onready var in_game_screen: InGameScreen = $InGameScreen


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if in_game_screen.visible:
			in_game_screen.hide_screen()
		else:
			in_game_screen.show_screen()

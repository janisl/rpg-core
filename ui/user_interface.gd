extends CanvasLayer

@onready var player_hud: PlayerHud = $PlayerHud
@onready var in_game_screen: InGameScreen = $InGameScreen


func _ready() -> void:
	EventBus.player_spawned.connect(_on_player_spawned)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if in_game_screen.visible:
			in_game_screen.hide_screen()
		else:
			in_game_screen.show_screen()


func _on_player_spawned(player: Player) -> void:
	player_hud.connect_to_player(player)
	in_game_screen.connect_to_player(player)

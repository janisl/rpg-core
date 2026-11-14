extends CanvasLayer

@onready var player_hud: PlayerHud = $PlayerHud
@onready var in_game_screen: InGameScreen = $InGameScreen

var _current_in_game_screen: Control


func _ready() -> void:
	EventBus.player_spawned.connect(_on_player_spawned)


func _input(event: InputEvent) -> void:
	if _current_in_game_screen && event.is_action_pressed("ui_cancel"):
		close_in_game_screen()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _current_in_game_screen:
		return

	if event.is_action_pressed("inventory"):
		if in_game_screen.visible:
			in_game_screen.hide_screen()
		else:
			in_game_screen.show_screen()


func show_in_game_screen(scene: PackedScene) -> Control:
	_current_in_game_screen = scene.instantiate()
	add_child(_current_in_game_screen)
	EventBus.in_game_screen_shown.emit(_current_in_game_screen)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return _current_in_game_screen


func close_in_game_screen() -> void:
	if not _current_in_game_screen:
		return

	EventBus.in_game_screen_closed.emit(_current_in_game_screen)
	_current_in_game_screen.queue_free()
	_current_in_game_screen = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_player_spawned(player: Player) -> void:
	player_hud.connect_to_player(player)
	in_game_screen.connect_to_player(player)

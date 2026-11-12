extends CanvasLayer

@onready var player_hud: PlayerHud = $PlayerHud
@onready var in_game_screen: InGameScreen = $InGameScreen
@onready var external_iventory: ExternalInventory = $ExternalIventory


func _ready() -> void:
	EventBus.player_spawned.connect(_on_player_spawned)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if in_game_screen.visible:
			in_game_screen.hide_screen()
		else:
			in_game_screen.show_screen()


func show_loot_inventory(player: Player, loot_inventory: Inventory) -> void:
	external_iventory.initialize(player, loot_inventory)
	external_iventory.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_player_spawned(player: Player) -> void:
	player_hud.connect_to_player(player)
	in_game_screen.connect_to_player(player)

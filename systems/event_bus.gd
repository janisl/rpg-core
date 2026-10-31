extends Node

@warning_ignore_start("unused_signal")

signal player_spawned(player: Player)

signal new_game_started
signal load_level_started
signal load_level_progress(value: float)
signal load_level_finished

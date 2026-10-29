extends Node


func transition_to_level(level_path: String) -> void:
	_save_player_state()
	load_new_level(level_path)


func load_new_level(level_path: String) -> void:
	get_tree().change_scene_to_file(level_path)
	await get_tree().scene_changed


func _save_player_state() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var state := PlayerState.new()
	state.version = 1
	state.state = player.save_state()

	var path := "user://player.tres"

	ResourceSaver.save(state, path)

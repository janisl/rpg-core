extends Node


func load_new_level(level_path: String) -> void:
	get_tree().change_scene_to_file(level_path)
	await get_tree().scene_changed

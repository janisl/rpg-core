extends Node


func transition_to_level(level_path: String) -> void:
	_save_player_state()
	if get_tree().current_scene.scene_file_path == "res://levels/test.tscn":
		_save_level_state()

	await load_new_level(level_path)

	_load_player_state()


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


func _load_player_state() -> void:
	var path := "user://player.tres"
	var state := ResourceLoader.load(path)

	var player := get_tree().get_first_node_in_group("player") as Player
	player.load_state(state.state)
	player.position = Vector3.ZERO


func _save_level_state() -> void:
	var state := LevelState.new()
	state.version = 1

	_save_level_objects(state)

	var path := "user://level.tres"
	ResourceSaver.save(state, path)


func _save_level_objects(state: LevelState) -> void:
	var objects_to_persist := get_tree().get_nodes_in_group("persist")
	for obj in objects_to_persist:
		assert(obj.has_method("save_state"), "Missing save_state method")
		var obj_state: Dictionary = obj.save_state()
		obj_state.scene_file_path = obj.scene_file_path
		obj_state.name = obj.name
		obj_state.parent_path = obj.get_parent().get_path()
		state.saved_objects.append(obj_state)

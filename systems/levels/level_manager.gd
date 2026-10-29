extends Node

const TEMP_SLOT = "temp"


func transition_to_level(level_path: String) -> void:
	_save_player_state()
	if get_tree().current_scene.scene_file_path == "res://levels/test.tscn":
		_save_level_state()

	await load_new_level(level_path)

	if _player_state_exists(TEMP_SLOT):
		_load_player_state()
	if get_tree().current_scene.scene_file_path == "res://levels/test.tscn" and _level_state_exists(TEMP_SLOT, "test"):
		await _load_level_state()


func load_new_level(level_path: String) -> void:
	get_tree().change_scene_to_file(level_path)
	await get_tree().scene_changed


func _save_player_state() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var state := PlayerState.new()
	state.version = 1
	state.state = player.save_state()

	_write_player_state(TEMP_SLOT, state)


func _load_player_state() -> void:
	var state := _read_player_state(TEMP_SLOT)

	var player := get_tree().get_first_node_in_group("player") as Player
	player.load_state(state.state)
	player.position = Vector3.ZERO


func _save_level_state() -> void:
	var state := LevelState.new()
	state.version = 1

	_save_level_objects(state)

	_write_level_state(TEMP_SLOT, "test", state)


func _load_level_state() -> void:
	var state := _read_level_state(TEMP_SLOT, "test")

	await _load_level_objects(state)


func _save_level_objects(state: LevelState) -> void:
	var objects_to_persist := get_tree().get_nodes_in_group("persist")
	for obj in objects_to_persist:
		assert(obj.has_method("save_state"), "Missing save_state method")
		var obj_state: Dictionary = obj.save_state()
		obj_state.scene_file_path = obj.scene_file_path
		obj_state.name = obj.name
		obj_state.parent_path = obj.get_parent().get_path()
		state.saved_objects.append(obj_state)


func _load_level_objects(state: LevelState) -> void:
	var existing_objects := get_tree().get_nodes_in_group("persist")
	for obj in existing_objects:
		obj.queue_free()

	await get_tree().process_frame

	for obj_state in state.saved_objects:
		var obj: Node = load(obj_state.scene_file_path).instantiate()
		get_tree().current_scene.get_node(obj_state.parent_path).add_child(obj)
		obj.name = obj_state.name

	for obj_state in state.saved_objects:
		var n: String = obj_state.name
		var obj := get_tree().current_scene.get_node(obj_state.parent_path).get_node(n)
		obj.load_state(obj_state)


func _get_player_state_file_name(slot: String) -> String:
	return "user://" + slot + "/player.tres"


func _read_player_state(slot: String) -> PlayerState:
	var path := _get_player_state_file_name(slot)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)


func _write_player_state(slot: String, state: PlayerState) -> void:
	var dir := DirAccess.open("user://")
	dir.make_dir(slot)
	var path := _get_player_state_file_name(slot)
	ResourceSaver.save(state, path, ResourceSaver.FLAG_CHANGE_PATH)


func _player_state_exists(slot: String) -> bool:
	var path := _get_player_state_file_name(slot)
	return FileAccess.file_exists(path)


func _get_level_state_file_name(slot: String, level_name: String) -> String:
	return "user://" + slot + "/level_" + level_name + ".tres"


func _read_level_state(slot: String, level_name: String) -> LevelState:
	var path := _get_level_state_file_name(slot, level_name)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)


func _write_level_state(slot: String, level_name: String, state: LevelState) -> void:
	var dir := DirAccess.open("user://")
	dir.make_dir(slot)
	var path := _get_level_state_file_name(slot, level_name)
	ResourceSaver.save(state, path, ResourceSaver.FLAG_CHANGE_PATH)


func _level_state_exists(slot: String, level_name: String) -> bool:
	var path := _get_level_state_file_name(slot, level_name)
	return FileAccess.file_exists(path)

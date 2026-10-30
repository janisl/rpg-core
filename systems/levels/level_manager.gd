extends Node

const SAVE_VERSION = 1
const TEMP_SLOT = "temp"
const SAVES_ROOT = "user://"
const STATE_FILE_EXT = ".tres"


func _ready() -> void:
	_clear_slot(TEMP_SLOT)


func transition_to_level(level_path: String) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	_save_player_state(TEMP_SLOT, player)
	if get_tree().current_scene.scene_file_path == "res://levels/test.tscn":
		_save_level_state(TEMP_SLOT, get_tree().current_scene.name)

	await load_new_level(level_path)

	player = get_tree().get_first_node_in_group("player") as Player
	_load_player_state(TEMP_SLOT, player)
	player.position = Vector3.ZERO
	if get_tree().current_scene.scene_file_path == "res://levels/test.tscn":
		await _load_level_state(TEMP_SLOT, get_tree().current_scene.name)


func load_new_level(level_path: String) -> void:
	get_tree().change_scene_to_file(level_path)
	await get_tree().scene_changed


func _load_player_state(slot: String, player: Player) -> void:
	if not _player_state_exists(slot):
		return
	var state := _read_player_state(slot)
	player.load_state(state.state)


func _save_player_state(slot: String, player: Player) -> void:
	var state := PlayerState.new()
	state.version = SAVE_VERSION
	state.state = player.save_state()
	_write_player_state(slot, state)


func _load_level_state(slot: String, level_name: String) -> void:
	if not _level_state_exists(slot, level_name):
		return
	var state := _read_level_state(slot, level_name)
	await _load_level_objects(state)


func _save_level_state(slot: String, level_name: String) -> void:
	var state := LevelState.new()
	state.version = SAVE_VERSION
	_save_level_objects(state)
	_write_level_state(slot, level_name, state)


func _save_level_objects(state: LevelState) -> void:
	var objects_to_persist := get_tree().get_nodes_in_group("persist")
	for obj in objects_to_persist:
		assert(obj.has_method("save_state"), "Missing save_state method")
		assert(obj.scene_file_path, "Not a scene instance")
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
		var parent := get_node(obj_state.parent_path)
		assert(parent, "Missing parent")
		var obj: Node = load(obj_state.scene_file_path).instantiate()
		parent.add_child(obj)
		obj.name = obj_state.name

	for obj_state in state.saved_objects:
		var obj := get_node(obj_state.parent_path).get_node(str(obj_state.name))
		assert(obj, "Object disappeared")
		obj.load_state(obj_state)


func _get_player_state_file_name(slot: String) -> String:
	return _get_slot_path(slot) + "player" + STATE_FILE_EXT


func _read_player_state(slot: String) -> PlayerState:
	var path := _get_player_state_file_name(slot)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)


func _write_player_state(slot: String, state: PlayerState) -> void:
	_create_slot_dir(slot)
	var path := _get_player_state_file_name(slot)
	ResourceSaver.save(state, path, ResourceSaver.FLAG_CHANGE_PATH)


func _player_state_exists(slot: String) -> bool:
	var path := _get_player_state_file_name(slot)
	return FileAccess.file_exists(path)


func _get_level_state_file_name(slot: String, level_name: String) -> String:
	return _get_slot_path(slot) + "level_" + level_name + STATE_FILE_EXT


func _read_level_state(slot: String, level_name: String) -> LevelState:
	var path := _get_level_state_file_name(slot, level_name)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)


func _write_level_state(slot: String, level_name: String, state: LevelState) -> void:
	_create_slot_dir(slot)
	var path := _get_level_state_file_name(slot, level_name)
	ResourceSaver.save(state, path, ResourceSaver.FLAG_CHANGE_PATH)


func _level_state_exists(slot: String, level_name: String) -> bool:
	var path := _get_level_state_file_name(slot, level_name)
	return FileAccess.file_exists(path)


func _get_slot_path(slot: String) -> String:
	return SAVES_ROOT + slot + "/"


func _create_slot_dir(slot: String) -> void:
	var dir := DirAccess.open(SAVES_ROOT)
	dir.make_dir(slot)


func _clear_slot(slot: String) -> void:
	var dir := DirAccess.open(_get_slot_path(slot))
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.remove(file_name) != OK:
				print("Deleting file " + file_name + " failed.")
			file_name = dir.get_next()

	var root_dir := DirAccess.open(SAVES_ROOT)
	if root_dir:
		if root_dir.remove(slot) != OK:
			print("Deleting slot dir failed.")

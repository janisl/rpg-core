extends Node

const SAVE_VERSION = 1
const TEMP_SLOT = "temp"
const SAVES_ROOT = "user://saves/"
const STATE_FILE_EXT = ".tres"

var current_player: Player


func _ready() -> void:
	_clear_slot(TEMP_SLOT)


func load_game(slot: String) -> void:
	if !_player_state_exists(slot):
		return

	_copy_slot(slot, TEMP_SLOT)
	var state := _read_player_state(slot)

	await _load_new_level(state.current_scene_path)

	_load_from_temp()


func save_game(slot: String, screenshot_image: Image) -> void:
	_save_to_temp(screenshot_image)
	_copy_slot(TEMP_SLOT, slot)


func delete_save(slot: String) -> bool:
	var path := _get_slot_path(slot)
	if not DirAccess.dir_exists_absolute(path):
		return false
	OS.move_to_trash(ProjectSettings.globalize_path(path))
	return true


func transition_to_level(level_path: String) -> void:
	_save_to_temp(null)

	await _load_new_level(level_path)

	_load_from_temp()
	current_player.position = Vector3.ZERO


func get_slot_screenshot(slot: String) -> ImageTexture:
	var image := _read_screenshot(slot)
	return ImageTexture.create_from_image(image) if image else null


func _load_new_level(level_path: String) -> void:
	get_tree().change_scene_to_file(level_path)
	await get_tree().scene_changed
func _load_from_temp() -> void:
	_load_level_state(TEMP_SLOT, _get_current_level_state_name())
	_load_player_state(TEMP_SLOT, current_player)


func _save_to_temp(screenshot_image: Image) -> void:
	_save_level_state(TEMP_SLOT, _get_current_level_state_name())
	_save_player_state(TEMP_SLOT, current_player)
	_write_screenshot(TEMP_SLOT, screenshot_image)




func _load_player_state(slot: String, player: Player) -> void:
	if not _player_state_exists(slot):
		return
	var state := _read_player_state(slot)
	player.load_state(state.state)


func _save_player_state(slot: String, player: Player) -> void:
	var state := PlayerState.new()
	state.version = SAVE_VERSION
	state.current_scene_path = get_tree().current_scene.scene_file_path
	state.savetime = int(Time.get_unix_time_from_system())
	state.state = player.save_state()
	_write_player_state(slot, state)


func _load_level_state(slot: String, level_name: String) -> void:
	if not _level_state_exists(slot, level_name):
		return
	var state := _read_level_state(slot, level_name)
	_load_level_objects(state)


func _save_level_state(slot: String, level_name: String) -> void:
	var state := LevelState.new()
	state.version = SAVE_VERSION
	_save_level_objects(state)
	_write_level_state(slot, level_name, state)


func _load_level_objects(state: LevelState) -> void:
	var existing_objects := _gather_existing_persist_objects()
	_create_missing_persist_objects(existing_objects, state.saved_objects)
	_free_deleted_persist_objects(existing_objects, state.saved_objects)
	_load_persist_object_states(existing_objects, state.saved_objects)


func _gather_existing_persist_objects() -> Dictionary[NodePath, Node]:
	var existing_objects: Dictionary[NodePath, Node]
	for obj in get_tree().get_nodes_in_group("persist"):
		existing_objects[obj.get_path()] = obj
	return existing_objects


func _create_missing_persist_objects(existing_objects: Dictionary[NodePath, Node], saved_objects: Dictionary[NodePath, Dictionary]) -> void:
	for obj_path in saved_objects:
		if existing_objects.has(obj_path):
			continue

		var obj_state := saved_objects[obj_path]
		var parent := get_node(obj_state.parent_path)
		assert(parent, "Missing parent")
		assert(obj_state.scene_file_path, "Dynamic object without a scene")

		var obj: Node = load(obj_state.scene_file_path).instantiate()
		parent.add_child(obj)
		obj.name = obj_state.name
		existing_objects[obj_path] = obj


func _free_deleted_persist_objects(existing_objects: Dictionary[NodePath, Node], saved_objects: Dictionary[NodePath, Dictionary]) -> void:
	var paths := existing_objects.keys()
	for obj_path: NodePath in paths:
		if saved_objects.has(obj_path):
			continue
		existing_objects[obj_path].queue_free()
		existing_objects.erase(obj_path)


func _load_persist_object_states(existing_objects: Dictionary[NodePath, Node], saved_objects: Dictionary[NodePath, Dictionary]) -> void:
	for obj_path in saved_objects:
		existing_objects[obj_path].load_state(saved_objects[obj_path])


func _save_level_objects(state: LevelState) -> void:
	var objects_to_persist := get_tree().get_nodes_in_group("persist")
	for obj in objects_to_persist:
		assert(obj.has_method("save_state"), "Missing save_state method")
		var obj_state: Dictionary = obj.save_state()
		obj_state.scene_file_path = obj.scene_file_path
		obj_state.name = obj.name
		obj_state.parent_path = obj.get_parent().get_path()
		state.saved_objects[obj.get_path()] = obj_state


func _get_current_level_state_name() -> String:
	var path := get_tree().current_scene.scene_file_path
	return path.replace("res://", "").replace(".tscn", "").replace("/", "_")


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
	return _get_slot_path(slot) + level_name + STATE_FILE_EXT


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


func _get_screenshot_file_name(slot: String) -> String:
	return _get_slot_path(slot) + "screenshot.png"


func _read_screenshot(slot: String) -> Image:
	var path := _get_screenshot_file_name(slot)
	if FileAccess.file_exists(path):
		return Image.load_from_file(path)
	return null


func _write_screenshot(slot: String, image: Image) -> void:
	if not image:
		return
	_create_slot_dir(slot)
	var path := _get_screenshot_file_name(slot)
	image.save_png(path)


func _get_slot_path(slot: String) -> String:
	return SAVES_ROOT + slot + "/"


func _create_slot_dir(slot: String) -> void:
	var path := _get_slot_path(slot)
	DirAccess.make_dir_recursive_absolute(path)


func _clear_slot(slot: String) -> void:
	var path := _get_slot_path(slot)
	var dir := DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.remove(file_name) != OK:
			print("Deleting file " + file_name + " failed.")
		file_name = dir.get_next()

	if DirAccess.remove_absolute(path) != OK:
		print("Deleting slot dir failed.")


func _copy_slot(slot_from: String, slot_to: String) -> bool:
	_clear_slot(slot_to)
	_create_slot_dir(slot_to)

	var from_path := _get_slot_path(slot_from)
	var to_path := _get_slot_path(slot_to)
	var from_dir := DirAccess.open(from_path)
	if not from_dir:
		return false
	from_dir.list_dir_begin()
	var file_name := from_dir.get_next()
	while file_name != "":
		if from_dir.copy(from_path + file_name, to_path + file_name, -1) != OK:
			print("Copying file " + file_name + " failed.")
			return false
		file_name = from_dir.get_next()
	return true

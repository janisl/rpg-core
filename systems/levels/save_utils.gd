class_name SaveUtils

## Marks a saved blackboard value as a Node reference stored by path.
const NODE_REF_PREFIX := "@node_ref:"


static func save_ref(state: Dictionary, name: StringName, value: Variant) -> void:
	if value and value is Node:
		state[name] = value.get_path()


static func load_ref(state: Dictionary, name: StringName) -> Node:
	if not state.has(name):
		return null
	return LevelManager.get_node_or_null(state[name])


static func save_timer(state: Dictionary, name: StringName, timer: Timer) -> void:
	if not timer:
		return

	state[name] = {
			&"running": not timer.is_stopped(),
			&"time_left": timer.time_left,
			&"wait_time": timer.wait_time,
			&"paused": timer.paused,
		}


static func load_timer(state: Dictionary, name: StringName, timer: Timer) -> void:
	if not timer or not state.has(name):
		return

	var timer_state: Dictionary = state[name]
	timer.stop()
	if timer_state.get(&"running", false):
		timer.start(timer_state.get(&"time_left", timer.wait_time))
	timer.wait_time = timer_state.get(&"wait_time", timer.wait_time)
	timer.paused = timer_state.get(&"paused", false)


static func save_state_chart(state: Dictionary, name: StringName, chart: StateChart) -> void:
	if not chart:
		return

	state[name] = StateChartSerializer.serialize(chart)


static func load_state_chart(state: Dictionary, name: StringName, chart: StateChart) -> void:
	if not chart or not state.has(name):
		return

	StateChartSerializer.deserialize(state[name], chart)


static func save_animation_player(state: Dictionary, name: StringName, animation_player: AnimationPlayer) -> void:
	if not animation_player or not animation_player.current_animation:
		return

	state[name] = {
			&"is_playing": animation_player.is_playing(),
			&"current_animation": animation_player.current_animation,
			&"animation_position": animation_player.current_animation_position
		}


static func load_animation_player(state: Dictionary, name: StringName, animation_player: AnimationPlayer) -> void:
	if not animation_player or not state.has(name):
		return

	var player_state: Dictionary = state[name]
	animation_player.play(player_state[&"current_animation"])
	animation_player.seek(player_state.get(&"animation_position", 0.0))
	if not player_state.get(&"is_playing", false):
		animation_player.stop(false)


## Saves the blackboard, the running [NpcBTAction] leaves with their state, and
## the leaves already completed in running composites (see [NpcBTAction]).
static func save_bt_player(state: Dictionary, name: StringName, player: BTPlayer) -> void:
	if not player or not player.get_bt_instance():
		return

	var running: Array[Dictionary] = []
	var completed: Array[Array] = []
	_collect_bt_progress(player.get_bt_instance().get_root_task(), [], running, completed)
	state[name] = {
			&"blackboard": _encode_blackboard(player.blackboard.get_vars_as_dict()),
			&"running": running,
			&"completed": completed,
		}


## Restarts the tree, restores the blackboard and prepares saved leaves to
## resume or be skipped on their next run. Call before restoring state the
## leaves depend on, since restarting exits the currently running tasks.
static func load_bt_player(state: Dictionary, name: StringName, player: BTPlayer) -> void:
	if not player or not player.get_bt_instance() or not state.has(name):
		return

	var bt_state: Dictionary = state[name]
	player.restart()
	player.blackboard.populate_from_dict(_decode_blackboard(bt_state.get(&"blackboard", {})))

	var root: BTTask = player.get_bt_instance().get_root_task()
	for path: Array in bt_state.get(&"completed", []):
		_mark_skipped(_get_task_at(root, path))
	for entry: Dictionary in bt_state.get(&"running", []):
		var task := _get_task_at(root, entry.get(&"path", [])) as NpcBTAction
		if task:
			task._load_state(entry.get(&"state", {}))
			task.resuming = true


static func _collect_bt_progress(task: BTTask, path: Array, running: Array[Dictionary], completed: Array[Array]) -> void:
	if task.get_child_count() == 0:
		if task is NpcBTAction:
			running.append({ &"path": path, &"state": (task as NpcBTAction)._save_state() })
		return

	var reached_running := false
	for i in task.get_child_count():
		var child := task.get_child(i)
		var child_path := path + [i]
		if child.get_status() == BT.RUNNING:
			reached_running = true
			_collect_bt_progress(child, child_path, running, completed)
		elif child.get_status() == BT.SUCCESS:
			# Statuses of children not ticked in this run are stale. Earlier
			# sequence children and parallel children are ticked every run.
			if task is BTParallel or (task is BTSequence and not reached_running):
				completed.append(child_path)


static func _get_task_at(root: BTTask, path: Array) -> BTTask:
	var task := root
	for index: int in path:
		if not task or index >= task.get_child_count():
			return null
		task = task.get_child(index)
	return task


static func _mark_skipped(task: BTTask) -> void:
	if not task:
		return
	if task is NpcBTAction:
		(task as NpcBTAction).skip = true
	for i in task.get_child_count():
		_mark_skipped(task.get_child(i))


## Replaces Node values with prefixed path strings, since nodes can't be saved.
static func _encode_blackboard(vars: Dictionary) -> Dictionary:
	var encoded := Dictionary()
	for key: StringName in vars:
		var value: Variant = vars[key]
		if value is Object and not is_instance_valid(value):
			value = null
		elif value is Node:
			value = NODE_REF_PREFIX + String((value as Node).get_path())
		encoded[key] = value
	return encoded


static func _decode_blackboard(vars: Dictionary) -> Dictionary:
	var decoded := Dictionary()
	for key: StringName in vars:
		var value: Variant = vars[key]
		if value is String and value.begins_with(NODE_REF_PREFIX):
			value = LevelManager.get_node_or_null(NodePath(value.trim_prefix(NODE_REF_PREFIX)))
		decoded[key] = value
	return decoded

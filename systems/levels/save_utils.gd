class_name SaveUtils


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
	animation_player.play(player_state[&"animation_name"])
	animation_player.seek(player_state.get(&"animation_position", 0.0))
	if not player_state.get(&"is_playing", false):
		animation_player.stop(false)

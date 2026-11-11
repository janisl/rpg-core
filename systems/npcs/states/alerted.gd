extends NpcStateProcessor

@export var alerted_sound: AudioStream
@export var must_have_been_the_wind_sound: AudioStream
@export var initial_shock_time := 1.5
@export var wait_time_once_reached := 5.0

var _alerted_action: NpcAlertedAction


func _enter_tree() -> void:
	_alerted_action = NpcAlertedAction.new(npc, initial_shock_time, wait_time_once_reached)
	_alerted_action.gave_up.connect(_return_to_patrol)
	add_child(_alerted_action)


func save_state() -> Dictionary:
	return _alerted_action.save_state()


func load_state(state: Dictionary) -> void:
	_alerted_action.load_state(state)


func _on_alerted_state_entered() -> void:
	_enter_state()
	_alerted_action.start()
	play_sound(alerted_sound)


func _on_alerted_state_exited() -> void:
	_exit_state()


func _on_alerted_state_physics_processing(delta: float) -> void:
	if not npc.has_attention_target():
		state_chart.send_event("idle")
		return

	_alerted_action.physics_process(delta)


func _return_to_patrol() -> void:
	state_chart.send_event("idle")
	play_sound(must_have_been_the_wind_sound)

@tool
extends NpcActionLeaf

@export var alerted_sound: AudioStream
@export var must_have_been_the_wind_sound: AudioStream
@export var initial_shock_time := 1.5
@export var wait_time_once_reached := 5.0

var _alerted_action: NpcAlertedAction


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_alerted_action = NpcAlertedAction.new(npc, initial_shock_time, wait_time_once_reached)
	add_child(_alerted_action)


func _start() -> void:
	_alerted_action.start()
	npc.play_sound(alerted_sound)


func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if not npc.has_attention_target():
		npc.end_alert()
		return FAILURE

	_alerted_action.physics_process(get_physics_process_delta_time())

	if _alerted_action.has_given_up():
		npc.end_alert()
		npc.play_sound(must_have_been_the_wind_sound)
		return SUCCESS

	return RUNNING

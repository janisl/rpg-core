extends NpcStateProcessor

@export var sight_detection: SightDetection
@export var searching_look_ahead_pivot: Node3D
@export var searching_look_ahead: Node3D

@export var reacquire_time := 0.5
@export var head_target_rotation_angle := 60.0
@export var reset_suspicion_when_search_ends := true
@export var wait_at_first_point := 5.0
@export var end_search_after_second_point := 3.0
@export var end_search_if_stuck_for := 10.0

@export var searching_sound: AudioStream
@export var end_search_sound: AudioStream
@export var i_see_you_sound: AudioStream

@export var show_search_points := false

var _search_action: NpcSearchAction


func _enter_tree() -> void:
	_search_action = NpcSearchAction.new(npc)
	_search_action.sight_detection = sight_detection
	_search_action.searching_look_ahead_pivot = searching_look_ahead_pivot
	_search_action.searching_look_ahead = searching_look_ahead
	_search_action.reacquire_time = reacquire_time
	_search_action.head_target_rotation_angle = head_target_rotation_angle
	_search_action.wait_at_first_point = wait_at_first_point
	_search_action.end_search_after_second_point = end_search_after_second_point
	_search_action.end_search_if_stuck_for = end_search_if_stuck_for
	_search_action.show_search_points = show_search_points
	_search_action.target_spotted.connect(play_sound.bind(i_see_you_sound))
	_search_action.target_reacquired.connect(_start_chasing)
	_search_action.search_ended.connect(_end_search)
	add_child(_search_action)


func save_state() -> Dictionary:
	return _search_action.save_state()


func load_state(state: Dictionary) -> void:
	_search_action.load_state(state)


func _on_searching_state_entered() -> void:
	_enter_state()
	_search_action.start()
	play_sound(searching_sound)
	npc.set_lower_body_walk()


func _on_searching_state_exited() -> void:
	_exit_state()
	_search_action.stop()


func _on_searching_state_physics_processing(delta: float) -> void:
	_search_action.physics_process(delta)


func _start_chasing() -> void:
	npc.attention_target = npc.search_target
	state_chart.send_event("chase")


func _end_search() -> void:
	play_sound(end_search_sound)
	if reset_suspicion_when_search_ends:
		npc.reset_suspicion()
	state_chart.send_event("idle")

@tool
extends NpcActionLeaf

## Succeeds when the target is reacquired, fails when the search ends and combat is over.

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

enum Result { SEARCHING, REACQUIRED, ENDED }

var _search_action: NpcSearchAction
var _result := Result.SEARCHING


func _ready() -> void:
	if Engine.is_editor_hint():
		return

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
	_search_action.target_spotted.connect(func() -> void: npc.play_sound(i_see_you_sound))
	_search_action.target_reacquired.connect(func() -> void: _result = Result.REACQUIRED)
	_search_action.search_ended.connect(func() -> void: _result = Result.ENDED)
	add_child(_search_action)


func _start() -> void:
	_result = Result.SEARCHING
	_search_action.start()
	npc.play_sound(searching_sound)
	npc.set_lower_body_walk()


func _stop() -> void:
	_search_action.stop()


func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if _result == Result.SEARCHING:
		_search_action.physics_process(get_physics_process_delta_time())

	match _result:
		Result.REACQUIRED:
			npc.attention_target = npc.search_target
			return SUCCESS
		Result.ENDED:
			npc.play_sound(end_search_sound)
			if reset_suspicion_when_search_ends:
				npc.reset_suspicion()
			npc.end_combat()
			return FAILURE

	return RUNNING

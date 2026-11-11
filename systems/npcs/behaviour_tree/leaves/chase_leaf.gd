@tool
extends NpcActionLeaf

## Succeeds when the target is caught, fails when it is lost.

@export var target_melee_distance := 1.5
@export var target_ranged_distance_offset := 1.0
@export var start_chase_sound: AudioStream
@export var giveup_chase_time := 5.0
@export var wait_after_broken_los_time := 3.0
@export var face_target_while_waiting := true

@export_flags_3d_physics var collision_mask := (
	PhysicsLayers.WORLD_MASK |
	PhysicsLayers.PLAYER_MASK |
	PhysicsLayers.NPCS_MASK |
	PhysicsLayers.DYNAMIC_OBJECTS_MASK
)

var _chase_action: NpcChaseAction
var _has_lost_target := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_chase_action = NpcChaseAction.new(npc)
	_chase_action.target_melee_distance = target_melee_distance
	_chase_action.target_ranged_distance_offset = target_ranged_distance_offset
	_chase_action.giveup_chase_time = giveup_chase_time
	_chase_action.wait_after_broken_los_time = wait_after_broken_los_time
	_chase_action.face_target_while_waiting = face_target_while_waiting
	_chase_action.collision_mask = collision_mask
	_chase_action.line_of_sight_broken.connect(func(point: Vector3) -> void: npc.broken_los_point = point)
	_chase_action.target_lost.connect(_on_target_lost)
	add_child(_chase_action)


func _start() -> void:
	_has_lost_target = false
	var target := npc.attention_target as Player

	if not target or npc.is_neutral_to_player():
		_has_lost_target = true
		npc.set_lower_body_walk()
		return

	if npc.previous_behaviour != Npc.BehaviourState.Attacking:
		npc.play_sound(start_chase_sound)
	npc.set_lower_body_run()
	npc.set_upper_body_raised_weapon()
	_chase_action.start(target)


func _stop() -> void:
	_chase_action.stop()


func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if _has_lost_target:
		return FAILURE

	if _chase_action.physics_process(get_physics_process_delta_time()) == NpcChaseAction.Outcome.CAUGHT:
		return SUCCESS

	# Losing the target can also happen on a timer, between ticks
	return FAILURE if _has_lost_target else RUNNING


func _on_target_lost() -> void:
	if _has_lost_target:
		return

	_has_lost_target = true
	npc.remember_lost_target(_chase_action.chase_target)
	npc.set_lower_body_walk()

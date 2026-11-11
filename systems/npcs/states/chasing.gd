extends NpcStateProcessor

@export var target_melee_distance := 1.5
@export var target_ranged_distance_offset := 1.0
@export var action_when_caught := "attack"
@export var start_chase_sound: AudioStream
@export var giveup_chase_time := 5.0
@export var wait_after_broken_los_time := 3.0
@export var face_target_while_waiting := true
@export var searching_state: NpcStateProcessor

@export_flags_3d_physics var collision_mask := (
	PhysicsLayers.WORLD_MASK |
	PhysicsLayers.PLAYER_MASK |
	PhysicsLayers.NPCS_MASK |
	PhysicsLayers.DYNAMIC_OBJECTS_MASK
)

var _chase_action: NpcChaseAction


func _enter_tree() -> void:
	_chase_action = NpcChaseAction.new(npc)
	_chase_action.target_melee_distance = target_melee_distance
	_chase_action.target_ranged_distance_offset = target_ranged_distance_offset
	_chase_action.giveup_chase_time = giveup_chase_time
	_chase_action.wait_after_broken_los_time = wait_after_broken_los_time
	_chase_action.face_target_while_waiting = face_target_while_waiting
	_chase_action.collision_mask = collision_mask
	_chase_action.line_of_sight_broken.connect(_on_line_of_sight_broken)
	_chase_action.target_lost.connect(_start_searching)
	add_child(_chase_action)


func save_state() -> Dictionary:
	return _chase_action.save_state()


func load_state(state: Dictionary) -> void:
	_chase_action.load_state(state)


func _on_chasing_state_entered() -> void:
	_enter_state()
	var target := npc.attention_target as Player

	if not target or npc.is_neutral_to_player():
		state_chart.send_event("search")
		npc.set_lower_body_walk()
		return

	if npc.previous_behaviour != Npc.BehaviourState.Attacking:
		play_sound(start_chase_sound)
	npc.set_lower_body_run()
	npc.set_upper_body_raised_weapon()
	_chase_action.start(target)


func _on_chasing_state_exited() -> void:
	_exit_state()
	_chase_action.stop()


func _on_chasing_state_physics_processing(delta: float) -> void:
	if _chase_action.physics_process(delta) == NpcChaseAction.Outcome.CAUGHT:
		state_chart.send_event(action_when_caught)


func _on_line_of_sight_broken(point: Vector3) -> void:
	searching_state.broken_los_point = point


func _start_searching() -> void:
	var sight := npc.sight_detection
	sight.current_suspicion -= sight.aggro_threshold / 4
	searching_state.player = _chase_action.chase_target
	searching_state.last_known_player_point = npc.last_reachable_path
	state_chart.send_event("search")
	npc.set_lower_body_walk()

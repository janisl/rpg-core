class_name Npc
extends Actor

enum BehaviourState {
	None,
	Idle,
	Patrolling,
	Investigating,
	Alerted,
	Chasing,
	Attacking,
	Searching,
}

@export var display_name: String

@export var patrol_path: PatrolPath

@export_group("Movement")
@export var walk_speed := 2.0
@export var sprint_speed := 4.0
@export var acceleration := 10.0
@export var rotation_speed := 0.2

@export_group("NPC Behaviour")
@export_enum("Friendly", "Neutral", "Hostile") var response_to_player := "Neutral"
@export var weapon_stack: ItemStack
## Drive behaviour with the behaviour tree instead of the state chart's Behaviour region.
@export var use_behaviour_tree := false
@export var behaviour_tree: BeehaveTree

@export_group("Head LookAt")
@export var head_turner: LookAtModifier3D

@export_group("Footstep Player")
@export var footsteps_enabled := true
@export var walk_volume_db := -38.0
@export var sprint_volume_db := -30.0
@export var wiggle_on_walking_speed := 8.0
@export var wiggle_on_sprinting_speed := 12.0

var attention_target: Node3D:
	set(value):
		if attention_target and attention_target is AttentionPoint:
			attention_target.queue_free()
		attention_target = value

var move_speed := 2.0
var last_reachable_path: Vector3

# Search memory, written when a chase loses its target and read while searching
var broken_los_point: Vector3
var last_known_target_point: Vector3
var search_target: Player:
	get:
		if not search_target:
			return get_tree().get_first_node_in_group("player")
		return search_target

# One-off stimuli, consumed by _select_behaviour() on the next physics frame
var _was_alerted := false
var _alert_attention_point := Callable()
var _heard_suspicious_noise := false
var _noise_attention_point := Callable()

# Behaviour tree memory: which sticky behaviour the NPC is committed to
var _in_combat := false
var _investigating := false
var _alerted := false

var previous_behaviour: BehaviourState
var current_behaviour: BehaviourState

var _health: HealthAttribute

var _weapon_data: WeaponData
var _weapon: Weapon
var _weapon_third_person: ThirdPersonWieldable

var _can_play_footstep := true
var _wiggle_vector := Vector2.ZERO
var _wiggle_index := 0.0

@onready var velocity_debug_shape: MeshInstance3D = $VelocityDebugShape
@onready var sight_detection: SightDetection = $SightDetection
@onready var hearing_detection: HearingDetection = $HearingDetection
@onready var hand_slot: Node3D = %HandSlot
@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var state_chart: StateChart = $StateChart
@onready var footstep_player: FootstepPlayer = $FootstepPlayer

@onready var patrolling_processor: NpcStateProcessor = $StateChart/Root/Behaviour/Patrolling/Processor
@onready var investigate_processor: NpcStateProcessor = $StateChart/Root/Behaviour/Investigating/Processor
@onready var chasing_processor: NpcStateProcessor = $StateChart/Root/Behaviour/Chasing/Processor
@onready var attacking_processor: NpcStateProcessor = $StateChart/Root/Behaviour/Attacking/Processor
@onready var searching_processor: NpcStateProcessor = $StateChart/Root/Behaviour/Searching/Processor
@onready var alerted_processor: NpcStateProcessor = $StateChart/Root/Behaviour/Alerted/Processor


func _enter_tree() -> void:
	# Must run before the state chart and the tree are ready
	if use_behaviour_tree:
		$StateChart/Root/Behaviour.initial_state = NodePath("TreeControlled")
		behaviour_tree.enabled = true


func _ready() -> void:
	add_to_group("persist")
	_spawn_weapon()
	_find_health_attribute()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if footsteps_enabled:
		_npc_footsteps(delta)

	if use_behaviour_tree:
		_update_behaviour_memory()
	else:
		_select_behaviour()


func face_direction(target_position: Vector3) -> void:
	var direction := global_position.direction_to(target_position)
	direction.y = 0.0
	if direction.is_zero_approx():
		return

	var target_basis := Basis.looking_at(direction, Vector3.UP, false)
	basis = basis.slerp(target_basis, rotation_speed)


func in_state(states: Array[BehaviourState]) -> bool:
	return states.any(func(state: BehaviourState) -> bool: return current_behaviour == state)


func is_using_weapon() -> bool:
	return _weapon != null


func equip_weapon() -> void:
	if _weapon_third_person:
		_weapon_third_person.show()


func unequip_weapon() -> void:
	if _weapon_third_person:
		_weapon_third_person.hide()


func get_weapon_range() -> float:
	return _weapon_data.weapon_range


func do_weapon_attack() -> void:
	if not _can_attack_with_weapon():
		return

	var player_sight_collision_point := sight_detection.player_sight_collision_point
	if player_sight_collision_point != Vector3.ZERO:
		var from_position := head.global_position
		var forward_direction := from_position.direction_to(player_sight_collision_point)
		_weapon.update(from_position, forward_direction, false, false, false)
		_weapon.state_chart.send_event("onFiring")


func move_npc_to_next_position(_delta: float) -> void:
	var next_position := nav_agent.get_next_path_position()
	if nav_agent.is_target_reachable():
		last_reachable_path = next_position

	var direction := global_position.direction_to(next_position)
	if direction:
		var face_dir := global_position + velocity
		face_direction(face_dir)
		var new_velocity := direction * move_speed
		velocity.x = velocity.move_toward(new_velocity, .25).x
		velocity.z = velocity.move_toward(new_velocity, .25).z
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()


func stop_moving(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, delta * move_speed)
	velocity.z = move_toward(velocity.z, 0, delta * move_speed)
	move_and_slide()


func has_attention_target() -> bool:
	return is_instance_valid(attention_target)


func is_neutral_to_player() -> bool:
	return response_to_player == "Neutral"


func has_patrol_path() -> bool:
	return patrol_path != null


## Returns the player if a hostile NPC bumped into them this frame, otherwise null.
func find_bumped_hostile_target() -> Player:
	if response_to_player != "Hostile":
		return null

	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider is Player:
			return collider as Player

	return null


func play_sound(sound: AudioStream) -> void:
	var audio := get_node_or_null("Audio") as AudioStreamPlayer3D
	if audio and sound:
		audio.stream = sound
		audio.play()


func is_in_combat() -> bool:
	return _in_combat


func is_investigating() -> bool:
	return _investigating


func is_alerted() -> bool:
	return _alerted


func start_combat(target: Node3D) -> void:
	attention_target = target
	_in_combat = true
	_investigating = false
	_alerted = false


func end_combat() -> void:
	_in_combat = false


func end_alert() -> void:
	_alerted = false


func set_upper_body_neutral() -> void:
	state_chart.send_event("ubody_neutral")


func set_upper_body_raised_weapon() -> void:
	state_chart.send_event("ubody_raise_weapon")


func set_upper_body_attack() -> void:
	state_chart.send_event("ubody_attack")


func set_lower_body_walk() -> void:
	state_chart.send_event("body_walk")


func set_lower_body_run() -> void:
	state_chart.send_event("body_run")


func is_suspicion_cleared() -> bool:
	return sight_detection.current_suspicion <= 0 and hearing_detection.current_suspicion <= 0


func remember_lost_target(target: Player) -> void:
	search_target = target
	last_known_target_point = last_reachable_path
	sight_detection.current_suspicion -= sight_detection.aggro_threshold / 4


func reset_suspicion() -> void:
	if hearing_detection:
		hearing_detection.reset()
	if sight_detection:
		sight_detection.reset()


## Something alarming happened, such as taking damage or an impact noise nearby.
## place_attention_point is called only if the NPC reacts, so the current attention target
## isn't replaced while e.g. chasing.
func notify_alerted(place_attention_point: Callable) -> void:
	_was_alerted = true
	_alert_attention_point = place_attention_point


## A noise was suspicious enough to investigate.
## place_attention_point is called only if the NPC reacts.
func notify_suspicious_noise(place_attention_point: Callable) -> void:
	_heard_suspicious_noise = true
	_noise_attention_point = place_attention_point


func is_dead() -> bool:
	return _health and _health.value <= 0


func save_state() -> Dictionary:
	var state := super()
	SaveUtils.save_state_chart(state, &"state_chart", state_chart)
	SaveUtils.save_ref(state, &"attention_target", attention_target)

	state[&"move_speed"] = move_speed
	state[&"last_reachable_path"] = last_reachable_path
	state[&"broken_los_point"] = broken_los_point
	state[&"last_known_target_point"] = last_known_target_point
	SaveUtils.save_ref(state, &"search_target", search_target)
	state[&"previous_behaviour"] = previous_behaviour
	state[&"current_behaviour"] = current_behaviour
	state[&"in_combat"] = _in_combat
	state[&"investigating"] = _investigating
	state[&"alerted"] = _alerted

	state[&"weapon_equiped"] = _weapon_third_person && _weapon_third_person.visible
	if head_turner:
		state[&"head_turner_active"] = head_turner.active
		state[&"head_turner_target"] = head_turner.target_node

	state[&"patrolling_processor"] = patrolling_processor.save_state()
	state[&"investigate_processor"] = investigate_processor.save_state()
	state[&"chasing_processor"] = chasing_processor.save_state()
	state[&"attacking_processor"] = attacking_processor.save_state()
	state[&"searching_processor"] = searching_processor.save_state()
	state[&"alerted_processor"] = alerted_processor.save_state()
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	SaveUtils.load_state_chart(state, &"state_chart", state_chart)
	attention_target = SaveUtils.load_ref(state, &"attention_target")

	move_speed = state.get(&"move_speed", move_speed)
	last_reachable_path = state.get(&"last_reachable_path", Vector3.ZERO)
	broken_los_point = state.get(&"broken_los_point", Vector3.ZERO)
	last_known_target_point = state.get(&"last_known_target_point", Vector3.ZERO)
	search_target = SaveUtils.load_ref(state, &"search_target")
	previous_behaviour = state.get(&"previous_behaviour", BehaviourState.None)
	current_behaviour = state.get(&"current_behaviour", BehaviourState.None)
	_in_combat = state.get(&"in_combat", false)
	_investigating = state.get(&"investigating", false)
	_alerted = state.get(&"alerted", false)

	if _weapon_third_person:
		_weapon_third_person.visible = state.get(&"weapon_equiped", false)
	if head_turner:
		head_turner.active = state.get(&"head_turner_active", false)
		head_turner.target_node = state.get(&"head_turner_target", head_turner.target_node)

	patrolling_processor.load_state(state.get(&"patrolling_processor", Dictionary()))
	investigate_processor.load_state(state.get(&"investigate_processor", Dictionary()))
	chasing_processor.load_state(state.get(&"chasing_processor", Dictionary()))
	attacking_processor.load_state(state.get(&"attacking_processor", Dictionary()))
	searching_processor.load_state(state.get(&"searching_processor", Dictionary()))
	alerted_processor.load_state(state.get(&"alerted_processor", Dictionary()))


## Picks behaviour transitions from perception. To be replaced by the behaviour tree.
func _select_behaviour() -> void:
	if _was_alerted:
		_was_alerted = false
		if in_state([BehaviourState.Idle, BehaviourState.Patrolling]):
			_alert_attention_point.call()
			state_chart.send_event("alerted")

	if _heard_suspicious_noise:
		_heard_suspicious_noise = false
		if in_state([BehaviourState.Idle, BehaviourState.Patrolling, BehaviourState.Alerted]):
			_noise_attention_point.call()
			state_chart.send_event("investigate")

	if in_state([BehaviourState.Investigating]):
		if sight_detection.is_aggro_on_player():
			sight_detection.current_suspicion = sight_detection.investigation_threshold
			attention_target = sight_detection.ref_to_player
			state_chart.send_event("chase")
		elif is_suspicion_cleared():
			state_chart.send_event("idle")
	elif in_state([BehaviourState.Idle, BehaviourState.Patrolling, BehaviourState.Alerted]) and sight_detection.is_suspicious_of_player():
		sight_detection.generate_attention_target(sight_detection.ref_to_player.global_position)
		state_chart.send_event("investigate")


## Turns perception and stimuli into behaviour tree memory. Mirrors _select_behaviour().
func _update_behaviour_memory() -> void:
	if _was_alerted:
		_was_alerted = false
		if not (_in_combat or _investigating or _alerted):
			_alert_attention_point.call()
			_alerted = true

	if _heard_suspicious_noise:
		_heard_suspicious_noise = false
		if not (_in_combat or _investigating):
			_noise_attention_point.call()
			_investigating = true
			_alerted = false

	if _in_combat:
		return

	if _investigating:
		if sight_detection.is_aggro_on_player():
			sight_detection.current_suspicion = sight_detection.investigation_threshold
			start_combat(sight_detection.ref_to_player)
		elif is_suspicion_cleared():
			_investigating = false
	elif sight_detection.is_suspicious_of_player():
		sight_detection.generate_attention_target(sight_detection.ref_to_player.global_position)
		_investigating = true
		_alerted = false


func _spawn_weapon() -> void:
	if not weapon_stack:
		return

	_weapon_data = weapon_stack.item
	_weapon = _weapon_data.controller_scene.instantiate()
	add_child(_weapon)
	_weapon.initialize(self, null, weapon_stack)

	_weapon_third_person = _weapon_data.third_person_scene.instantiate()
	hand_slot.add_child(_weapon_third_person)
	_weapon_third_person.initialize(_weapon, 1)
	_weapon_third_person.hide()


func _can_attack_with_weapon() -> bool:
	if _weapon_data.weapon_range <= 0.0:
		return true
	var ref_to_player := sight_detection.ref_to_player
	if not ref_to_player:
		return false
	return not _weapon._fire_rate_timer > 0 and global_position.distance_to(ref_to_player.global_position) <= _weapon_data.weapon_range


func _find_health_attribute() -> void:
	_health = find_children("", "HealthAttribute", true).front()


func _on_health_attribute_damage_taken(hit_info: HitInfo) -> void:
	# Damage without a direction is environmental and has no source to react to
	if not hit_info.direction.is_zero_approx():
		notify_alerted(sight_detection.generate_attention_target.bind(hit_info.source_position))


func _npc_footsteps(delta: float) -> void:
	if round(velocity.length()) >= sprint_speed:
		_wiggle_vector.y = sin(_wiggle_index)
		_wiggle_index += wiggle_on_walking_speed * delta

		if _can_play_footstep and _wiggle_vector.y > 0.9:
			footstep_player.play_footstep(sprint_volume_db, 1)
			_can_play_footstep = false

		if !_can_play_footstep and _wiggle_vector.y < 0.9:
			_can_play_footstep = true

	elif velocity.length() >= 0.2:
		_wiggle_vector.y = sin(_wiggle_index)
		_wiggle_index += wiggle_on_sprinting_speed * delta

		if _can_play_footstep and _wiggle_vector.y > 0.9:
			footstep_player.play_footstep(walk_volume_db, 1)
			_can_play_footstep = false

		if !_can_play_footstep and _wiggle_vector.y < 0.9:
			_can_play_footstep = true

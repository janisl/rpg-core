class_name Npc
extends Actor

const SIGHT_POINT = preload("uid://de4wqr4onwgie")
const HEARING_POINT = preload("uid://b4r73momnv102")

@export var display_name: String

@export var patrol_path: PatrolPath
@export var sounds: NpcSounds

@export_group("Movement")
@export var walk_speed := 2.0
@export var sprint_speed := 4.0
@export var acceleration := 15.0
@export var deceleration := 30.0
@export var rotation_speed := 0.2

@export_group("NPC Behaviour")
@export_enum("Friendly", "Neutral", "Hostile") var response_to_player := "Neutral"
@export var weapon_stack: ItemStack

@export_group("Head LookAt")
@export var head_turner: LookAtModifier3D

@export_group("Footstep Player")
@export var footsteps_enabled := true
@export var walk_volume_db := -38.0
@export var sprint_volume_db := -30.0
@export var wiggle_on_walking_speed := 8.0
@export var wiggle_on_sprinting_speed := 12.0

var sight_attention_point: AttentionPoint
var hearing_attention_point: AttentionPoint
var chase_target: Actor

var move_speed := 2.0
var last_reachable_path: Vector3

var broken_los_point: Vector3
var last_known_target_point: Vector3

var _was_alerted := false
var _heard_suspicious_noise := false

var _alerted := false
var _investigating := false
var _in_combat := false

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
@onready var audio: AudioStreamPlayer3D = $Audio

@onready var idle_action: NpcIdleAction = $IdleAction
@onready var patrol_action: NpcPatrolAction = $PatrolAction
@onready var investigate_action: NpcInvestigateAction = $InvestigateAction
@onready var chase_action: NpcChaseAction = $ChaseAction
@onready var attack_action: NpcAttackAction = $AttackAction
@onready var search_action: NpcSearchAction = $SearchAction
@onready var alerted_action: NpcAlertedAction = $AlertedAction


func _ready() -> void:
	add_to_group("persist")
	_spawn_weapon()
	_find_health_attribute()
	_create_attention_points.call_deferred()
	nav_agent.velocity_computed.connect(_on_velocity_computed)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if footsteps_enabled:
		_npc_footsteps(delta)

	if _was_alerted:
		_was_alerted = false
		if not (_investigating or _alerted or _in_combat):
			_alerted = true
			state_chart.send_event("alerted")

	if _heard_suspicious_noise:
		_heard_suspicious_noise = false
		if not (_investigating or _in_combat):
			start_investigating()
			state_chart.send_event("chase")


func _exit_tree() -> void:
	if sight_attention_point:
		sight_attention_point.queue_free()
	if hearing_attention_point:
		hearing_attention_point.queue_free()


func set_sight_target(pos: Vector3) -> void:
	if chase_target:
		return
	sight_attention_point.global_position = pos
	sight_attention_point.is_active = true


func set_hearing_target(pos: Vector3) -> void:
	if chase_target:
		return
	hearing_attention_point.global_position = pos
	hearing_attention_point.is_active = true


func face_direction(target_position: Vector3) -> void:
	var direction := global_position.direction_to(target_position)
	direction.y = 0.0
	if direction.is_zero_approx():
		return

	var target_basis := Basis.looking_at(direction, Vector3.UP, false)
	basis = basis.slerp(target_basis, rotation_speed)


func play_sound(sound: AudioStream) -> void:
	if audio and sound:
		audio.stream = sound
		audio.play()


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
		_weapon.update(from_position, forward_direction, false, false, false, false)
		_weapon.state_chart.send_event("onFiring")


func set_walking_speed() -> void:
	move_speed = walk_speed
	state_chart.send_event("body_walk")


func set_running_speed() -> void:
	move_speed = sprint_speed
	state_chart.send_event("body_run")


func move_npc_to_next_position(_delta: float) -> void:
	var next_position := nav_agent.get_next_path_position()
	if nav_agent.is_target_reachable():
		last_reachable_path = next_position

	var direction := global_position.direction_to(next_position)
	if direction:
		var face_dir := global_position + velocity
		face_direction(face_dir)
		nav_agent.velocity = direction * move_speed
	else:
		nav_agent.velocity = Vector3.ZERO
	if not nav_agent.avoidance_enabled:
		_on_velocity_computed(nav_agent.velocity)

	move_and_slide()


func stop_moving(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, delta * deceleration)
	velocity.z = move_toward(velocity.z, 0, delta * deceleration)
	nav_agent.velocity = Vector3.ZERO
	move_and_slide()


func set_upper_body_neutral() -> void:
	state_chart.send_event("ubody_neutral")


func set_upper_body_raised_weapon() -> void:
	state_chart.send_event("ubody_raise_weapon")


func set_upper_body_attack() -> void:
	state_chart.send_event("ubody_attack")


func has_patrol_path() -> bool:
	return patrol_path != null


func notify_alerted() -> void:
	_was_alerted = true


func notify_suspicious_noise() -> void:
	_heard_suspicious_noise = true


func is_alerted() -> bool:
	return _alerted


func end_alert() -> void:
	_alerted = false


func is_investigating() -> bool:
	return _investigating


func start_investigating() -> void:
	_investigating = true
	_alerted = false


func end_investigating() -> void:
	_investigating = false


func is_in_combat() -> bool:
	return _in_combat


func start_chasing(target: Actor) -> void:
	chase_target = target
	play_sound(sounds.start_chase_sound)
	_in_combat = true
	_investigating = false
	_alerted = false


func end_combat() -> void:
	chase_target = null
	_in_combat = false


func remember_lost_target() -> void:
	last_known_target_point = last_reachable_path
	sight_detection.current_suspicion -= sight_detection.aggro_threshold / 4


func is_hostile_towards(node: Node3D) -> bool:
	if not node:
		return false

	var health: BaseAttribute = node.get_node_or_null("HealthAttribute")
	if health and not health.is_alive:
		return false

	if node is Player:
		return response_to_player == "Hostile"
	return false


func has_valid_chase_target() -> bool:
	if not chase_target:
		return false
	if not is_hostile_towards(chase_target):
		chase_target = null
		return false
	return true


func is_dead() -> bool:
	return _health and _health.value <= 0


func save_state() -> Dictionary:
	var state := super()
	SaveUtils.save_state_chart(state, &"state_chart", state_chart)
	SaveUtils.save_ref(state, &"chase_target", chase_target)

	state[&"move_speed"] = move_speed
	state[&"last_reachable_path"] = last_reachable_path
	state[&"broken_los_point"] = broken_los_point
	state[&"last_known_target_point"] = last_known_target_point
	state[&"was_alerted"] = _was_alerted
	state[&"heard_suspicious_noise"] = _heard_suspicious_noise
	state[&"alerted"] = _alerted
	state[&"investigating"] = _investigating
	state[&"in_combat"] = _in_combat

	state[&"weapon_equiped"] = _weapon_third_person && _weapon_third_person.visible
	if head_turner:
		state[&"head_turner_active"] = head_turner.active
		state[&"head_turner_target"] = head_turner.target_node

	state[&"patrol_action"] = patrol_action.save_state()
	state[&"investigate_action"] = investigate_action.save_state()
	state[&"chase_action"] = chase_action.save_state()
	state[&"attack_action"] = attack_action.save_state()
	state[&"search_action"] = search_action.save_state()
	state[&"alerted_action"] = alerted_action.save_state()
	state[&"sight_attention_point"] = sight_attention_point.save_state()
	state[&"hearing_attention_point"] = hearing_attention_point.save_state()
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	SaveUtils.load_state_chart(state, &"state_chart", state_chart)
	chase_target = SaveUtils.load_ref(state, &"chase_target")

	move_speed = state.get(&"move_speed", move_speed)
	last_reachable_path = state.get(&"last_reachable_path", Vector3.ZERO)
	broken_los_point = state.get(&"broken_los_point", Vector3.ZERO)
	last_known_target_point = state.get(&"last_known_target_point", Vector3.ZERO)
	_was_alerted = state.get(&"was_alerted", false)
	_heard_suspicious_noise = state.get(&"heard_suspicious_noise", false)
	_alerted = state.get(&"alerted", false)
	_investigating = state.get(&"investigating", false)
	_in_combat = state.get(&"in_combat", false)

	if _weapon_third_person:
		_weapon_third_person.visible = state.get(&"weapon_equiped", false)
	if head_turner:
		head_turner.active = state.get(&"head_turner_active", false)
		head_turner.target_node = state.get(&"head_turner_target", head_turner.target_node)

	patrol_action.load_state(state.get(&"patrol_action", Dictionary()))
	investigate_action.load_state(state.get(&"investigate_action", Dictionary()))
	chase_action.load_state(state.get(&"chase_action", Dictionary()))
	attack_action.load_state(state.get(&"attack_action", Dictionary()))
	search_action.load_state(state.get(&"search_action", Dictionary()))
	alerted_action.load_state(state.get(&"alerted_action", Dictionary()))
	sight_attention_point.load_state(state.get(&"sight_attention_point", Dictionary()))
	hearing_attention_point.load_state(state.get(&"hearing_attention_point", Dictionary()))


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
	sight_detection.check_if_chase_target_in_los()
	var detected_target := sight_detection.detected_target
	if not detected_target:
		return false
	return not _weapon._fire_rate_timer > 0 and global_position.distance_to(detected_target.global_position) <= _weapon_data.weapon_range


func _find_health_attribute() -> void:
	_health = find_children("", "HealthAttribute", true).front()


func _on_health_attribute_damage_taken(hit_info: HitInfo) -> void:
	if not hit_info.direction.is_zero_approx():
		set_sight_target(hit_info.source_position)
		notify_alerted()


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


func _create_attention_points() -> void:
	sight_attention_point = SIGHT_POINT.instantiate()
	get_tree().current_scene.add_child(sight_attention_point)

	hearing_attention_point = HEARING_POINT.instantiate()
	get_tree().current_scene.add_child(hearing_attention_point)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	var target_velocity := Vector3(safe_velocity.x, velocity.y, safe_velocity.z)
	var accel := acceleration if not safe_velocity.is_zero_approx() else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * get_physics_process_delta_time())
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * get_physics_process_delta_time())

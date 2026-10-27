class_name Npc
extends Actor

enum BehaviourState {
	None,
	Idle,
	Chasing,
	Attacking,
}

@export_group("Movement")
@export var walk_speed := 2.0
@export var sprint_speed := 4.0
@export var acceleration := 10.0
@export var rotation_speed := 0.2

@export_group("NPC Behaviour")
@export_enum("Friendly", "Neutral", "Hostile") var response_to_player := "Neutral"
@export var weapon_stack: ItemStack

@export_group("Head LookAt")
@export var head_turner: LookAtModifier3D

var attention_target: Node3D
var move_speed := 2.0
var last_reachable_path: Vector3

var previous_behaviour: BehaviourState
var current_behaviour: BehaviourState

var _health: HealthAttribute

var _weapon_data: WeaponData
var _weapon: Weapon
var _weapon_third_person: ThirdPersonWieldable

@onready var velocity_debug_shape: MeshInstance3D = $VelocityDebugShape
@onready var sight_detection: SightDetection = $SightDetection
@onready var hand_slot: Node3D = %HandSlot
@onready var nav_agent: NavigationAgent3D = $NavAgent


func _ready() -> void:
	_spawn_weapon()
	_find_health_attribute()


func face_direction(target_position: Vector3) -> void:
	var direction := global_position.direction_to(target_position)
	direction.y = 0.0
	if direction.is_zero_approx():
		return

	var target_basis := Basis.looking_at(direction, Vector3.UP, false)
	basis = basis.slerp(target_basis, rotation_speed)


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


func move_npc_to_next_position(delta: float) -> void:
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

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()


func is_dead() -> bool:
	return _health and _health.value <= 0


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

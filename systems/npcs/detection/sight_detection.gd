class_name SightDetection
extends Node3D

@export_group("References")
@export var detection_area: Area3D
@export var npc: Npc

@export_group("Suspicion Build-Up")
@export var sight_suspicion_indicator: DetectionIndicator
@export var investigation_threshold := 3.0
@export var aggro_threshold := 5.0
@export var buildup_to_investigation_rate := 1.0
@export var buildup_to_aggro_rate := 3.0
@export_range(0, 100) var minimum_visibility := 0

@export_flags_3d_physics var collision_mask := (
	PhysicsLayers.WORLD_MASK |
	PhysicsLayers.PLAYER_MASK |
	PhysicsLayers.NPCS_MASK |
	PhysicsLayers.DYNAMIC_OBJECTS_MASK
)

@export_group("Debug")
@export var show_detection_line: bool = false

var ref_to_player: Player
var player_sight_collision_point := Vector3.ZERO
var current_suspicion := 0.0

var _nodes_inside_detection_area: Array[Node3D] = []


func _ready() -> void:
	_connect_detection_signals()


func _physics_process(delta: float) -> void:
	if npc.in_state([Npc.BehaviourState.Chasing, Npc.BehaviourState.Attacking]):
		return

	_update_suspicion_indicator()

	for node:Node in _nodes_inside_detection_area:
		if node is Player and npc.response_to_player != "Hostile":
			continue
		if _fire_raycast_at(node):
			var initial_amount := buildup_to_investigation_rate if npc.in_state([Npc.BehaviourState.Idle]) else buildup_to_aggro_rate
			var amount := initial_amount * delta
			current_suspicion = clamp(current_suspicion + amount, 0, aggro_threshold + 0.5)

	_state_trigger_checks()


func check_if_player_in_los() -> bool:
	for	node:Node in _nodes_inside_detection_area:
		if node is Player:
			return _fire_raycast_at(node)
	return false


func reset() -> void:
	current_suspicion = 0
	sight_suspicion_indicator.visible = false


func _connect_detection_signals() -> void:
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_nodes_inside_detection_area.append(body)


func _on_body_exited(body: Node3D) -> void:
	_nodes_inside_detection_area.erase(body)


func _fire_raycast_at(node: Node3D) -> bool:
	var space_state := get_world_3d().direct_space_state
	var end: Vector3 = node.head.global_position if node is Actor else node.global_position
	var query := PhysicsRayQueryParameters3D.create(npc.head.global_position, end)
	query.collision_mask = collision_mask
	query.exclude = [npc.get_rid(), detection_area.get_rid()]
	var result := space_state.intersect_ray(query)
	var last_raycasted_target: Node3D = result.collider if result else null
	if not last_raycasted_target:
		player_sight_collision_point = Vector3.ZERO
		return false
	if last_raycasted_target is not Player:
		player_sight_collision_point = Vector3.ZERO
		return false
	else:
		var player := last_raycasted_target as Player
		return _fire_raycast_at_player_result(result.position, player)


func _fire_raycast_at_player_result(pos: Vector3, player: Player) -> bool:
	player_sight_collision_point = pos
	ref_to_player = player
	if show_detection_line:
		DevTools.debug_line.draw_3d_line(npc.head.global_position, player.global_position, Color(1,0,0), 0.1)
	if ref_to_player.visibility_attribute:
		return ref_to_player.visibility_attribute.value >= minimum_visibility
	else:
		return true


func _update_suspicion_indicator() -> void:
	if sight_suspicion_indicator and current_suspicion > 0:
		if current_suspicion < investigation_threshold:
			sight_suspicion_indicator.is_investigating = false
			sight_suspicion_indicator.update(current_suspicion, investigation_threshold)
		else:
			sight_suspicion_indicator.is_investigating = true
			sight_suspicion_indicator.update(current_suspicion, aggro_threshold)


func _state_trigger_checks() -> void:
	if current_suspicion >= aggro_threshold and ref_to_player and npc.in_state([Npc.BehaviourState.Idle]):
		npc.attention_target = ref_to_player
		npc.state_chart.send_event("chase")

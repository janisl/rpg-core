class_name SightDetection
extends Node3D

@export_group("References")
@export var detection_area: Area3D
@export var npc: Npc

@export_group("Suspicion Build-Up")
@export_range(0, 100) var minimum_visibility := 0

@export_flags_3d_physics var collision_mask := (
	PhysicsLayers.WORLD_MASK |
	PhysicsLayers.PLAYER_MASK |
	PhysicsLayers.NPCS_MASK |
	PhysicsLayers.DYNAMIC_OBJECTS_MASK
)

@export_group("Debug")
@export var show_detection_line: bool = false

var _nodes_inside_detection_area: Array[Node3D] = []

var ref_to_player: Player
var player_sight_collision_point := Vector3.ZERO


func _ready() -> void:
	_connect_detection_signals()


func _physics_process(_delta: float) -> void:
	if check_if_player_in_los():
		npc.on_triggered()


func check_if_player_in_los() -> bool:
	for	node:Node in _nodes_inside_detection_area:
		if node is Player:
			return _fire_raycast_at(node)
	return false


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

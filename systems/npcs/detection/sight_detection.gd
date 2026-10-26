class_name SightDetection
extends Node3D

@export var detection_area: Area3D
@export var npc: Npc

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
	var query := PhysicsRayQueryParameters3D.create(npc.head.global_position, node.head.global_position if node is Actor else node.global_position)
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
	return true

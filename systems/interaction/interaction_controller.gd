class_name InteractionController
extends RayCast3D

signal interactable_seen(interactable)
signal interactable_unseen()

@export var show_debug_shapes : bool = false

var _interactable = null:
	set = _set_interactable

var _hotspot_base_pos_z : float = -1.5

@onready var shapecast : ShapeCast3D = $InteractionShapecast
@onready var hotspot : Node3D = $ShapecastHotspot
@onready var raycast_highlighter = $RaycastHighlighter
@onready var target_highlighter = $TargetHighlighter


func _ready() -> void:
	_hotspot_base_pos_z = hotspot.position.z
	if !show_debug_shapes:
		raycast_highlighter.visible = false
		target_highlighter.visible = false


func _process(_delta: float) -> void:
	_update_interactable()


func _set_interactable(value) -> void:
	_interactable = value
	if _interactable == null:
		interactable_unseen.emit()
	else:
		interactable_seen.emit(_interactable)


func _update_interactable() -> void:
	if show_debug_shapes:
		target_highlighter.visible = false

	if _is_interactable_freed():
		_interactable = null
		return

	var collider
	if is_colliding():
		collider = get_collider()

	var hotspot_global_position: Vector3 = get_collision_point() if collider else global_position

	if collider and not collider.is_in_group("interactable"):
		collider = null
		hotspot.global_position = hotspot_global_position
		if show_debug_shapes:
			raycast_highlighter.global_position = hotspot_global_position
			raycast_highlighter.visible = true
	else:
		hotspot.position = Vector3(0.0, 0.0, _hotspot_base_pos_z)
		if show_debug_shapes:
			raycast_highlighter.position = Vector3(0.0, 0.0, _hotspot_base_pos_z)
			raycast_highlighter.visible = false

	if not collider:
		if shapecast.is_colliding():
			var closest_distance = INF
			for i in range(shapecast.get_collision_count()):
				var shape_collider = shapecast.get_collider(i)
				if not shape_collider or not shape_collider.is_in_group("interactable"):
					continue
				var collision_point = shapecast.get_collision_point(i)
				var distance = collision_point.distance_squared_to(hotspot_global_position)
				if distance >= closest_distance:
					continue
				collider = shape_collider
				closest_distance = distance
				if show_debug_shapes:
					target_highlighter.global_position = collision_point
					target_highlighter.visible = true
	else:
		if show_debug_shapes:
			target_highlighter.global_position = hotspot_global_position
			target_highlighter.visible = true

	if collider == _interactable:
		return

	if collider == null and typeof(collider) != 0:
		collider = null

	_interactable = collider


func _is_interactable_freed() -> bool:
	return not is_instance_valid(_interactable) and typeof(_interactable) != 0

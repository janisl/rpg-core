class_name Actor
extends CharacterBody3D

signal ladder_entered(area: Area3D)
signal ladder_exited(area: Area3D)

const APPROX_MASS = 80.0
const SWIM_SUBMERGED_RATIO = 0.5

var _touching_swimmable_areas: Array[Area3D]
var touching_ladder_areas: Array[Area3D]


func _ready() -> void:
	pass


func on_swimmable_area_entered(area: Area3D) -> void:
	_touching_swimmable_areas.append(area)


func on_swimmable_area_exited(area: Area3D) -> void:
	_touching_swimmable_areas.erase(area)


func is_in_swimmable_area() -> bool:
	if _touching_swimmable_areas.is_empty():
		return false

	var body_bounds := _get_body_vertical_bounds()
	for area in _touching_swimmable_areas:
		if _get_submerged_ratio(area, body_bounds) >= SWIM_SUBMERGED_RATIO:
			return true
	return false


func _get_submerged_ratio(area: Area3D, body_bounds: Vector2) -> float:
	var body_height := body_bounds.y - body_bounds.x
	if body_height <= 0.0:
		return 0.0

	return clampf((_get_area_top_y(area) - body_bounds.x) / body_height, 0.0, 1.0)


func _get_body_vertical_bounds() -> Vector2:
	for child in get_children():
		if child is CollisionShape3D and not child.disabled:
			var half_extent := _shape_vertical_half_extent(child.shape)
			return Vector2(child.global_position.y - half_extent, child.global_position.y + half_extent)
	return Vector2(global_position.y, global_position.y)


func _get_area_top_y(area: Area3D) -> float:
	for child in area.get_children():
		if child is CollisionShape3D and not child.disabled:
			return child.global_position.y + _shape_vertical_half_extent(child.shape)
	return -INF


static func _shape_vertical_half_extent(shape: Shape3D) -> float:
	if shape is BoxShape3D:
		return shape.size.y * 0.5
	if shape is CapsuleShape3D or shape is CylinderShape3D:
		return shape.height * 0.5
	if shape is SphereShape3D:
		return shape.radius
	return 0.0


func on_ladder_area_entered(area: Area3D) -> void:
	touching_ladder_areas.append(area)
	ladder_entered.emit(area)


func on_ladder_area_exited(area: Area3D) -> void:
	touching_ladder_areas.erase(area)
	ladder_exited.emit(area)


func is_in_ladder_area() -> bool:
	return touching_ladder_areas.size() > 0


func push_away_rigid_bodies() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
			var diff = velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			diff = max(0.0, diff)
			var mass_ratio = min(1.0, APPROX_MASS / c.get_collider().mass)
			push_dir.y = 0
			var push_force = mass_ratio * 5.0
			c.get_collider().apply_impulse(push_dir * diff * push_force, c.get_position() - c.get_collider().global_position)


func get_look_at_angle(target_position: Vector3) -> float:
	var direction = global_position.direction_to(target_position)
	direction.y = 0.0
	if direction.is_zero_approx():
		return rotation.y

	return Vector3.FORWARD.angle_to(direction)

class_name Actor
extends CharacterBody3D

enum LiquidLevel { NONE, FEET, BODY, EYES }

signal ladder_entered(area: Area3D)
signal ladder_exited(area: Area3D)
signal liquid_level_changed

const APPROX_MASS = 80.0
const SWIM_SUBMERGED_RATIO = 0.5

@export var head: Node3D

var liquid_level := LiquidLevel.NONE :
	set(value):
		if liquid_level == value:
			return
		liquid_level = value
		liquid_level_changed.emit()

var _touching_liquids: Array[Area3D]
var touching_ladder_areas: Array[Area3D]


func _ready() -> void:
	pass


func on_liquid_entered(area: Area3D) -> void:
	_touching_liquids.append(area)


func on_liquid_exited(area: Area3D) -> void:
	_touching_liquids.erase(area)


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
			var push_dir := -c.get_normal()
			var diff: float = velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			diff = maxf(0.0, diff)
			var mass_ratio := minf(1.0, APPROX_MASS / c.get_collider().mass)
			push_dir.y = 0
			var push_force := mass_ratio * 5.0
			c.get_collider().apply_impulse(push_dir * diff * push_force, c.get_position() - c.get_collider().global_position)


func _update_liquid_level() -> void:
	if not _touching_liquids.size():
		liquid_level = LiquidLevel.NONE
		return

	var surface_y := -INF
	for area in _touching_liquids:
		surface_y = maxf(surface_y, _get_area_top_y(area))

	if surface_y <= global_position.z:
		liquid_level = LiquidLevel.NONE
		return

	if surface_y >= head.global_position.y:
		liquid_level = LiquidLevel.EYES
		return

	var body_bounds := _get_body_vertical_bounds()
	var body_height := body_bounds.y - body_bounds.x
	var submerge_ratio := clampf((surface_y - body_bounds.x) / body_height, 0.0, 1.0)

	liquid_level = LiquidLevel.FEET if submerge_ratio < SWIM_SUBMERGED_RATIO else LiquidLevel.BODY


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

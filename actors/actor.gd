class_name Actor
extends CharacterBody3D

const APPROX_MASS = 80.0

var _touching_swimmable_areas: Array[Area3D]
var touching_ladder_areas: Array[Area3D]


func _ready() -> void:
	pass


func on_swimmable_area_entered(area: Area3D) -> void:
	_touching_swimmable_areas.append(area)


func on_swimmable_area_exited(area: Area3D) -> void:
	_touching_swimmable_areas.erase(area)


func is_in_swimmable_area() -> bool:
	return _touching_swimmable_areas.size() > 0


func on_ladder_area_entered(area: Area3D) -> void:
	touching_ladder_areas.append(area)


func on_ladder_area_exited(area: Area3D) -> void:
	touching_ladder_areas.erase(area)


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

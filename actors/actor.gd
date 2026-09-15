class_name Actor
extends CharacterBody3D

const APPROX_MASS = 80.0


func _ready() -> void:
	pass


func is_in_swimmable_area() -> bool:
	return not get_tree().get_nodes_in_group("swimmable").all(func(area): return !area.overlaps_body(self))


func is_in_ladder_area() -> bool:
	return not get_tree().get_nodes_in_group("ladder").all(func(area): return !area.overlaps_body(self))


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

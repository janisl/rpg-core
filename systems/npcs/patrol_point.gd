@tool
extends Marker3D
class_name PatrolPoint

@export var next_patrol_points: Array[PatrolPoint] = []

var traversed := false
var previous_patrol_point: PatrolPoint

var _current_point_index := 0


func get_next_point() -> PatrolPoint:
	if (traversed and _current_point_index == 0) or next_patrol_points.is_empty():
		return _get_return_to_point()

	var next_patrol_point := next_patrol_points[_current_point_index]
	if not traversed:
		traversed = true
		next_patrol_point.previous_patrol_point = self

	_current_point_index = wrapi(_current_point_index + 1, 0, len(next_patrol_points) - 1)
	return next_patrol_point


func _get_return_to_point() -> PatrolPoint:
	var parent := get_parent() as PatrolPath
	if parent:
		if parent.starting_point_as_next_on_end:
			parent.starting_patrol_point.clear_traversals_bools()
			return parent.starting_patrol_point
		if previous_patrol_point == parent.starting_patrol_point:
			previous_patrol_point.clear_traversals_bools()
	return previous_patrol_point


func clear_traversals_bools() -> void:
	traversed = false
	if next_patrol_points.is_empty():
		return
	for point in next_patrol_points:
		if point.traversed:
			point.clear_traversals_bools()

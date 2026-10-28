extends Node3D
class_name PatrolPath

@export var starting_patrol_point : PatrolPoint
@export var starting_point_as_next_on_end := true

var _current_patrol_point: PatrolPoint


func target_next_patrol_point() -> PatrolPoint:
	if not _current_patrol_point:
		_current_patrol_point = starting_patrol_point
	_current_patrol_point = _current_patrol_point.get_next_point()
	return _current_patrol_point

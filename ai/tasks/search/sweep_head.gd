@tool
extends NpcBTAction
## Swings the search look-ahead point left and right so the head scans around.
## Never finishes; run it in parallel with movement.

@export var pivot_path: NodePath = ^"Rig/GeneralSkeleton/LookingPivot"
@export var max_angle := 60.0
@export var degrees_per_second := 180.0

var _pivot: Node3D
var _direction := 1.0


func _setup() -> void:
	_pivot = agent.get_node(pivot_path)


func _update(delta: float) -> Status:
	_pivot.rotation_degrees.y += _direction * degrees_per_second * delta
	if absf(_pivot.rotation_degrees.y) >= max_angle:
		_pivot.rotation_degrees.y = signf(_pivot.rotation_degrees.y) * max_angle
		_direction = -signf(_pivot.rotation_degrees.y)
	return RUNNING


func _end() -> void:
	_pivot.rotation_degrees.y = 0.0

@tool
extends Node3D
class_name PatrolPath

@export var starting_patrol_point : PatrolPoint
@export var starting_point_as_next_on_end := true

@export_group("Test simulation")
@export_tool_button("Generate Patrol Path", "Path3D") var button := _generate_path
@export var simulate_with: Actor

var _current_patrol_point: PatrolPoint


func target_next_patrol_point() -> PatrolPoint:
	if not _current_patrol_point:
		_current_patrol_point = starting_patrol_point
	_current_patrol_point = _current_patrol_point.get_next_point()
	return _current_patrol_point


func _generate_path() -> void:
	if not Engine.is_editor_hint():
		return

	for path in find_children("", "Path3D", false):
		path.free()
	for mesh in find_children("", "MeshInstance3D", false):
		mesh.free()

	if not starting_patrol_point:
		printerr("No starting patrol path is assigned!")
		return

	var patrol_point: PatrolPoint = starting_patrol_point
	if patrol_point.next_patrol_points.is_empty():
		printerr("Cannot generate a patrol path from a single point!")
		return

	starting_patrol_point.clear_traversals_bools()

	if simulate_with:
		var original_transform := simulate_with.global_transform
		var nav_agent : NavigationAgent3D = simulate_with.find_children("", "NavigationAgent3D").front()

		await _travel_path(nav_agent, simulate_with.global_position, simulate_with)

		simulate_with.global_transform = original_transform
	else:
		var nav_pointer := Node3D.new()
		patrol_point.add_child(nav_pointer)
		var nav_agent := NavigationAgent3D.new()
		nav_pointer.add_child(nav_agent)
		nav_agent.owner = get_tree().edited_scene_root
		nav_pointer.owner = get_tree().edited_scene_root

		await _travel_path(nav_agent, patrol_point.global_position, nav_pointer)

		nav_pointer.free()


func _travel_path(nav_agent: NavigationAgent3D, path_pos: Vector3, nav_pointer: Node3D) -> void:
	var path := _create_empty_path()
	path.owner = get_tree().edited_scene_root
	path.global_position = path_pos

	nav_agent.target_position = Vector3.ZERO
	var patrol_point := starting_patrol_point
	while (nav_agent.target_position != starting_patrol_point.global_position):
		patrol_point = patrol_point.get_next_point()
		nav_pointer.look_at(patrol_point.global_position, Vector3.UP)
		nav_agent.target_position = patrol_point.global_position
		while not nav_agent.is_target_reached():
			await get_tree().physics_frame
			var point := nav_agent.get_next_path_position()
			path.curve.add_point(path.to_local(point))
			nav_pointer.global_position = point
			if not nav_agent.is_target_reachable():
				_generate_pathing_failure(point)
				printerr("Unable to generate a complete path. Adjust your NavigationAgent3D or geometry.")
				return

		nav_pointer.global_position = patrol_point.global_position


func _create_empty_path() -> Path3D:
	var path := Path3D.new()
	path.name = "PatrolPath"
	path.debug_custom_color = Color(1,0,0)
	path.curve = Curve3D.new()
	path.curve.add_point(Vector3.ZERO)
	add_child(path)
	return path


func _generate_pathing_failure(pos: Vector3) -> void:
	var failure_point := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.DARK_RED
	failure_point.name = "PathfindingFail"
	sphere.radius = 0.5
	sphere.height = 1
	sphere.material = mat
	failure_point.mesh = sphere
	add_child(failure_point)
	failure_point.global_position = pos
	failure_point.owner = get_tree().edited_scene_root

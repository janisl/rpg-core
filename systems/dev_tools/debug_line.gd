extends Node2D

var lines: Array = []
var removed_line := false


func _process(delta: float) -> void:
	for i in range(len(lines)):
		lines[i].time -= delta

	if(len(lines) > 0 || removed_line):
		queue_redraw()
		removed_line = false


func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	for i in range(len(lines)):
		if(cam.is_position_behind(lines[i].start) ||
			cam.is_position_behind(lines[i].end)):
			continue

		var screen_point_start := cam.unproject_position(lines[i].start)
		var screen_point_end := cam.unproject_position(lines[i].end)
		draw_line(screen_point_start, screen_point_end, lines[i].line_color)

	var i := lines.size() - 1
	while (i >= 0):
		if(lines[i].time < 0.0):
			lines.remove_at(i)
			removed_line = true
		i -= 1


func draw_3d_line(start: Vector3, end: Vector3, line_color: Color, time: float = 0.0) -> void:
	lines.append(Line.new(start, end, line_color, time))


func draw_ray(start: Vector3, ray: Vector3, line_color: Color, time: float = 0.0) -> void:
	lines.append(Line.new(start, start + ray, line_color, time))


func draw_cube(center: Vector3, half_extents: float, line_color: Color, time: float = 0.0) -> void:
	var line_point_start := center
	line_point_start.x -= half_extents
	line_point_start.y += half_extents
	line_point_start.z -= half_extents

	# Top
	var line_point_end := line_point_start + Vector3(0, 0, half_extents * 2.0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(half_extents * 2.0, 0, 0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(0, 0, -half_extents * 2.0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(-half_extents * 2.0, 0, 0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);

	# Bottom
	line_point_start = line_point_end + Vector3(0, -half_extents * 2.0, 0)
	line_point_end = line_point_start + Vector3(0, 0, half_extents * 2.0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(half_extents * 2.0, 0, 0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(0, 0, -half_extents * 2.0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(-half_extents * 2.0, 0, 0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);

	# Sides
	line_point_start = line_point_end
	draw_3d_line(line_point_start, Vector3(0, half_extents * 2.0, 0), line_color, time)
	line_point_start += Vector3(0, 0, half_extents * 2.0)
	draw_3d_line(line_point_start, Vector3(0, half_extents * 2.0, 0), line_color, time)
	line_point_start += Vector3(half_extents * 2.0, 0, 0)
	draw_3d_line(line_point_start, Vector3(0, half_extents * 2.0, 0), line_color, time)
	line_point_start += Vector3(0, 0, -half_extents * 2.0)
	draw_3d_line(line_point_start, Vector3(0, half_extents * 2.0, 0), line_color, time)


class Line:
	var start: Vector3
	var end: Vector3
	var line_color: Color
	var time: float


	func _init(_start: Vector3, _end: Vector3, _line_color: Color, _time: float) -> void:
		start = _start
		end = _end
		line_color = _line_color
		time = _time

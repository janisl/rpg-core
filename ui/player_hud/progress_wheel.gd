class_name ProgressWheel
extends Control

@export var bg_color := Color(0,0,0,0.4)
@export var fg_color := Color(1,1,1,0.8)
@export var radius := 16.0
@export var width := 4.0

var current_angle_rad: float
var current_value: float:
	set(value):
		current_value = value
		update_wheel()


func update_wheel() -> void:
	current_angle_rad = minf(current_value * TAU, TAU)
	queue_redraw()


func _draw() -> void:
	if current_angle_rad > 0.0:
		draw_circle(Vector2.ZERO, radius, bg_color, false, width, true)
		draw_arc(Vector2.ZERO, radius, 0, current_angle_rad, 64, fg_color, width, true)

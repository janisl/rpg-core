class_name BulletTracer
extends Node3D

const MAX_LIFETIME_MS = 5000
const TRACER_LENGTH := 1.0

@export var speed := 75.0

@onready var spawn_time := Time.get_ticks_msec()

var target_pos := Vector3.ZERO


func _process(delta: float) -> void:
	var diff := target_pos - global_position
	var add := diff.normalized() * speed * delta
	add = add.limit_length(diff.length())
	global_position += add
	if global_position.distance_to(target_pos) <= TRACER_LENGTH or Time.get_ticks_msec() - spawn_time > MAX_LIFETIME_MS:
		queue_free()

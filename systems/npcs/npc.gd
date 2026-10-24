class_name Npc
extends Actor

@export_group("Movement")
@export var sprint_speed := 4.0
@export var acceleration := 10.0
@export var rotation_speed := 0.2

var attention_target: Node3D
var move_speed := 2.0


func face_direction(target_position: Vector3) -> void:
	var direction = global_position.direction_to(target_position)
	direction.y = 0.0
	if direction.is_zero_approx():
		return

	var target_basis = Basis.looking_at(direction, Vector3.UP, false)
	basis = basis.slerp(target_basis, rotation_speed)

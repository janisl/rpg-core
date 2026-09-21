class_name PlayerLadderMovementHandler
extends Node

@export_group("References")
@export var player: Player

@export_group("Movement settings")
@export var climb_speed := 7.0
@export var jump_off_speed := 10.0

var _cur_ladder_climbing: Area3D = null


func _on_handle_ladder_physics(_delta: float) -> void:
	var was_climbing_ladder := _cur_ladder_climbing and _cur_ladder_climbing.overlaps_body(player)
	if not was_climbing_ladder:
		_cur_ladder_climbing = null
		if player.touching_ladder_areas.size():
			_cur_ladder_climbing = player.touching_ladder_areas[0]

	if not _handle_ladder_movement(was_climbing_ladder):
		_cur_ladder_climbing = null
		if player.is_in_swimmable_area():
			player.state_chart.send_event("onSwimming")
		elif player.is_on_floor():
			player.state_chart.send_event("onGrounded")
		else:
			player.state_chart.send_event("onAirborne")
		return


func _handle_ladder_movement(was_climbing_ladder: bool) -> bool:
	if not _cur_ladder_climbing:
		return false

	var ladder_gtransform := _cur_ladder_climbing.global_transform
	var pos_rel_to_ladder := ladder_gtransform.affine_inverse() * player.global_position

	var wish_dir := (player.transform.basis * Vector3(player.input_dir.x, 0, player.input_dir.y)).normalized()

	var forward_move := player.input_dir.y
	var side_move := player.input_dir.x
	var ladder_forward_move := ladder_gtransform.affine_inverse().basis * player.camera_effects.global_transform.basis * Vector3(0, 0, forward_move)
	var ladder_side_move := ladder_gtransform.affine_inverse().basis * player.camera_effects.global_transform.basis * Vector3(side_move, 0, 0)

	var ladder_strafe_vel := climb_speed * (ladder_side_move.x + ladder_forward_move.x)
	var ladder_climb_vel := climb_speed * -ladder_side_move.z
	var cam_forward_amont := player.camera_effects.basis.z.dot(_cur_ladder_climbing.basis.z)
	var up_wish := Vector3.UP.rotated(Vector3(1, 0, 0), deg_to_rad(-45 * cam_forward_amont)).dot(ladder_forward_move)
	ladder_climb_vel += climb_speed * up_wish

	var should_dismount := false
	if not was_climbing_ladder:
		var mounting_from_top = pos_rel_to_ladder.y > _cur_ladder_climbing.get_node("TopOfLadder").position.y
		if mounting_from_top:
			if ladder_climb_vel > 0:
				should_dismount = true
		else:
			if (ladder_gtransform.affine_inverse().basis * wish_dir).z >= 0:
				should_dismount = true
		if abs(pos_rel_to_ladder.z) > 0.1:
			should_dismount = true

	if player.is_on_floor() and ladder_climb_vel <= 0:
		should_dismount = true

	if should_dismount:
		return false

	if was_climbing_ladder and Input.is_action_just_pressed("jump"):
		player.velocity = _cur_ladder_climbing.global_transform.basis.z * jump_off_speed
		return false

	player.velocity = ladder_gtransform.basis * Vector3(ladder_strafe_vel, ladder_climb_vel, 0)
	player.velocity = player.velocity.limit_length(climb_speed)

	pos_rel_to_ladder.z = 0
	player.global_position = ladder_gtransform * pos_rel_to_ladder

	player.move_and_slide()
	return true

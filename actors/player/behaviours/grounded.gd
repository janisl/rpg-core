extends PlayerStateBehaviour

const MIN_STEP_HEIGHT := 0.03

@export_group("Step settings")
@export var step_height := 0.5

var _snapped_to_stairs_last_frame := false
var _was_on_floor_last_frame := false


func _on_state_entered() -> void:
	_was_on_floor_last_frame = false


func _on_state_physics_processing(delta: float) -> void:
	player.previous_velocity = player.velocity

	var speed_modifier = player._sprint_modifier + player._crouch_modifier
	player._speed = player.default_speed + speed_modifier

	player.input_dir = Input.get_vector("left", "right", "forward", "backward")
	var current_velocity = Vector2(player.velocity.x, player.velocity.z)
	var direction := (player.transform.basis * Vector3(player.input_dir.x, 0, player.input_dir.y)).normalized()
	if direction:
		current_velocity = lerp(current_velocity, Vector2(direction.x, direction.z) * player._speed, player.acceleration)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, player.deceleration)

	player.velocity.x = current_velocity.x
	player.velocity.z = current_velocity.y

	if not _snap_up_stairs_check(delta):
		player.move_and_slide()
		_snap_down_to_stairs_check()

	_was_on_floor_last_frame = true

	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.jump()
		player.state_chart.send_event("onAirborne")
		return

	if not player.is_on_floor() and not _snapped_to_stairs_last_frame:
		player.state_chart.send_event("onAirborne")
		return


func _snap_up_stairs_check(delta) -> bool:
	if not player.is_on_floor() and not _snapped_to_stairs_last_frame:
		return false

	var up_check_result := PhysicsTestMotionResult3D.new()
	_run_body_test_motion(player.global_transform, Vector3(0, step_height * 2, 0), up_check_result)
	var test_step_height := up_check_result.get_travel().y

	var expected_move_motion: Vector3 = player.velocity * Vector3(1, 0, 1) * delta
	var step_pos_with_clearance := player.global_transform.translated(expected_move_motion + Vector3(0, test_step_height, 0))

	var down_check_result := PhysicsTestMotionResult3D.new()
	if not _run_body_test_motion(step_pos_with_clearance, Vector3(0, -test_step_height, 0), down_check_result):
		return false

	if not (down_check_result.get_collider() is StaticBody3D or down_check_result.get_collider() is CSGShape3D):
		return false

	var top_of_step: Vector3 = step_pos_with_clearance.origin + down_check_result.get_travel()
	var measured_height := (top_of_step - player.global_position).y
	var collision_point_height = (down_check_result.get_collision_point() - player.global_position).y
	if (
			measured_height > step_height
			or measured_height > test_step_height
			or (measured_height <= MIN_STEP_HEIGHT and collision_point_height <= MIN_STEP_HEIGHT)
			or collision_point_height > step_height
			or collision_point_height > test_step_height
	):
		return false

	player.stairs_ahead_ray_cast.global_position = down_check_result.get_collision_point() + Vector3(0, step_height, 0) + expected_move_motion.normalized() * 0.1
	player.stairs_ahead_ray_cast.force_raycast_update()
	if not player.stairs_ahead_ray_cast.is_colliding() or _is_surface_too_steep(player.stairs_ahead_ray_cast.get_collision_normal()):
		return false

	player.global_position = top_of_step
	player.apply_floor_snap()
	_snapped_to_stairs_last_frame = true
	player.camera_controller.smooth_step(measured_height)
	return true


func _snap_down_to_stairs_check() -> void:
	var did_snap := false
	var floor_below := player.stairs_below_ray_cast.is_colliding() and not _is_surface_too_steep(player.stairs_below_ray_cast.get_collision_normal())

	if not player.is_on_floor() and player.velocity.y <= 0 and (_was_on_floor_last_frame or _snapped_to_stairs_last_frame) and floor_below:
		var body_test_result := PhysicsTestMotionResult3D.new()
		if _run_body_test_motion(player.global_transform, Vector3(0, -step_height, 0), body_test_result):
			var translate_y := body_test_result.get_travel().y
			player.position.y += translate_y
			player.apply_floor_snap()
			did_snap = true
			player.camera_controller.smooth_step(translate_y)

	_snapped_to_stairs_last_frame = did_snap
var a: KinematicCollision3D

func _is_surface_too_steep(normal: Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > player.floor_max_angle


func _run_body_test_motion(from: Transform3D, motion: Vector3, result = null) -> bool:
	if not result:
		result = PhysicsTestMotionResult3D.new()

	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion

	return PhysicsServer3D.body_test_motion(player.get_rid(), params, result)

class_name SimpleEnemy
extends Enemy

@export var follow_speed := 3.0
@export var acceleration := 4.0
@export var deceleration := 5.0
@export var melee_range := 1.0
@export var melee_damage := 10.0

@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var state_chart: StateChart = $StateChart
@onready var health_component: HealthComponent = $HealthComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

var target: Node3D
var anim_tree_state: AnimationNodeStateMachinePlayback


func _ready() -> void:
	super()

	target = get_tree().get_first_node_in_group("player")

	health_component.died.connect(_on_died)
	nav_agent.velocity_computed.connect(_on_velocity_computed)

	anim_tree_state = animation_tree["parameters/playback"]
	animation_tree["parameters/Idle/TimeSeek/seek_request"] = randf_range(0.0, animation_player.get_animation("idle").length)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	_update_blends()


func on_triggered() -> void:
	state_chart.send_event("onChase")


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	var target_velocity = Vector3(safe_velocity.x, velocity.y, safe_velocity.z)
	var accel = acceleration if not safe_velocity.is_zero_approx() else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * get_physics_process_delta_time())
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * get_physics_process_delta_time())


func _on_died() -> void:
	queue_free()


func _on_chase_state_physics_processing(delta: float) -> void:
	if anim_tree_state.get_current_node() != "Chase":
		anim_tree_state.travel("Chase")

	if not target:
		return

	nav_agent.target_position = target.global_position

	var distance = global_position.distance_to(target.global_position)
	if distance <= melee_range:
		state_chart.send_event("onMelee")
		return

	if nav_agent.is_navigation_finished():
		nav_agent.velocity = Vector3.ZERO
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_pos)

	nav_agent.velocity = direction * follow_speed
	if not nav_agent.avoidance_enabled:
		_on_velocity_computed(nav_agent.velocity)

	if not direction.is_zero_approx():
		var target_rotation := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 5.0 * delta)


func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		on_triggered()


func _update_blends() -> void:
	var move_amount = velocity.length()
	move_amount = remap(move_amount, 0.0, follow_speed, 0.0, 1.0)
	animation_tree["parameters/Chase/IdleChaseBlend/blend_position"] = move_amount


func _attack() -> void:
	velocity = Vector3.ZERO
	nav_agent.velocity = Vector3.ZERO

	if target:
		var direction = global_position.direction_to(target.global_position)
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = target_rotation
		_apply_damage_to_target()

	if anim_tree_state.get_current_node() != "Melee":
		anim_tree_state.travel("Melee")
	else:
		anim_tree_state.start("Melee")

	await animation_tree.animation_finished

	if target:
		var distance = global_position.distance_to(target.global_position)
		if distance <= melee_range:
			_attack()
		else:
			state_chart.send_event("onChase")
	else:
		state_chart.send_event("onIdle")


func _on_melee_state_entered() -> void:
	_attack()


func _apply_damage_to_target() -> void:
	var health_component := target.get_node_or_null("HealthComponent") as HealthComponent

	if health_component:
		health_component.take_damage(melee_damage, self)

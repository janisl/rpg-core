class_name SimpleEnemy
extends Enemy

@export var follow_speed := 3.0

@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var state_chart: StateChart = $StateChart
@onready var health_component: HealthComponent = $HealthComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var target: Node3D


func _ready() -> void:
	super()

	target = get_tree().get_first_node_in_group("player")

	health_component.died.connect(_on_died)
	nav_agent.velocity_computed.connect(_on_velocity_computed)

	animation_player.play("idle")
	animation_player.seek(randf_range(0.0, animation_player.current_animation.length()))


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()


func on_triggered() -> void:
	state_chart.send_event("onChase")


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z


func _on_died() -> void:
	queue_free()


func _on_chase_state_physics_processing(delta: float) -> void:
	if not target:
		return

	nav_agent.target_position = target.global_position

	if nav_agent.is_navigation_finished():
		nav_agent.velocity = Vector3.ZERO
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()

	nav_agent.velocity = direction * follow_speed

	if animation_player.current_animation != "run":
		animation_player.play("run")

	if not direction.is_zero_approx():
		var target_rotation := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 5.0 * delta)


func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		on_triggered()

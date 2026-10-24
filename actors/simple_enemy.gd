class_name SimpleEnemy
extends Enemy

@export var follow_speed := 3.0
@export var acceleration := 4.0
@export var deceleration := 5.0
@export var melee_range := 1.0
@export var melee_damage := 10.0
@export var melee_hit_height := 1.0

@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var state_chart: StateChart = $StateChart
@onready var health_attribute: HealthAttribute = $HealthAttribute
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

var target: Node3D
var anim_tree_state: AnimationNodeStateMachinePlayback


func _ready() -> void:
	super()

	target = get_tree().get_first_node_in_group("player")

	health_attribute.died.connect(_on_died)
	nav_agent.velocity_computed.connect(_on_velocity_computed)

	anim_tree_state = animation_tree["parameters/playback"]
	animation_tree["parameters/Idle/TimeSeek/seek_request"] = randf_range(0.0, animation_player.get_animation("universal_animation_library_standard/Idle").length)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	_update_blends()


func on_triggered() -> void:
	state_chart.send_event("onChase")


func on_trigger(_player: Player) -> void:
	state_chart.send_event("onChase")


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	var target_velocity = Vector3(safe_velocity.x, velocity.y, safe_velocity.z)
	var accel = acceleration if not safe_velocity.is_zero_approx() else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * get_physics_process_delta_time())
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * get_physics_process_delta_time())


func _on_died() -> void:
	queue_free()


func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		on_triggered()


func _update_blends() -> void:
	var move_amount = velocity.length()
	move_amount = remap(move_amount, 0.0, follow_speed, 0.0, 1.0)
	animation_tree["parameters/Chase/IdleChaseBlend/blend_position"] = move_amount

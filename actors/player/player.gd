class_name Player
extends Actor

@export_group("References")
@export var camera_controller: CameraController
@export var camera_effects: CameraEffects
@export var state_chart: StateChart
@export var standing_collision: CollisionShape3D
@export var crouching_collision: CollisionShape3D
@export var crouch_check: ShapeCast3D
@export var interaction_ray_cast: InteractionRayCast
@export var stairs_ahead_ray_cast: RayCast3D
@export var stairs_below_ray_cast: RayCast3D
@export var weapon_controller: WeaponController
@export var animation_tree: AnimationTree
@export var inventory: Inventory

@export_group("Movement settings")
@export var jump_velocity := 5.0

@export_group("Render settings")
@export_flags_3d_render var mesh_layer := 1

var input_dir := Vector2.ZERO
var anim_tree_state: AnimationNodeStateMachinePlayback


func _ready() -> void:
	var meshes := find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		m.layers = mesh_layer
	anim_tree_state = animation_tree["parameters/playback"]


func _process(_delta: float) -> void:
	state_chart.set_expression_property("Looking at: ", interaction_ray_cast.current_object)

	var move_amount = velocity.length()
	animation_tree["parameters/Standing/blend_position"] = remap(move_amount, 0.0, 10.0, -1.0, 1.0)
	animation_tree["parameters/Crouching/blend_position"] = remap(move_amount, 0.0, 8.0, -1.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	if event.is_action_pressed("test"):
		$HealthComponent.take_damage(10.0)


func update_rotation(value: Vector3) -> void:
	global_transform.basis = Basis.from_euler(value)


func jump() -> void:
	velocity.y += jump_velocity


func _on_standing() -> void:
	standing_collision.disabled = false
	crouching_collision.disabled = true
	anim_tree_state.travel("Standing")


func _on_crouching() -> void:
	standing_collision.disabled = true
	crouching_collision.disabled = false
	anim_tree_state.travel("Crouching")


func _on_health_component_died() -> void:
	anim_tree_state.travel("Death")

class_name Player
extends Actor

@export_group("References")
@export var camera_controller: CameraController
@export var camera_effects: CameraEffects
@export var state_chart: StateChart
@export var standing_collision: CollisionShape3D
@export var crouching_collision: CollisionShape3D
@export var crouch_check: ShapeCast3D
@export var interaction_controller: InteractionController
@export var stairs_ahead_ray_cast: RayCast3D
@export var stairs_below_ray_cast: RayCast3D
@export var wield_controller: WieldController
@export var animation_tree: AnimationTree
@export var inventory: Inventory

@export_group("Movement settings")
@export var jump_velocity := 5.0
@export var crouch_jump_velocity := 3.0
@export var toggle_crouch := false

@export_group("Camera height")
@export var standing_camera_height := 1.6
@export var crouch_camera_height := 0.7
@export var death_camera_height := 0.1

@export_group("Damage effects")
@export var damage_kick_pitch := 5.0
@export var damage_kick_roll := 5.0
@export var damage_for_full_kick := 20.0

@export_group("Render settings")
@export_flags_3d_render var mesh_layer := 1

var input_dir := Vector2.ZERO
var try_crouch := false

var is_sprinting := false
var is_crouching := false

var anim_tree_state: AnimationNodeStateMachinePlayback

var player_attributes: Dictionary[String, BaseAttribute]
var health_attribute: HealthAttribute
var stamina_attribute: StaminaAttribute
var visibility_attribute: BaseAttribute

@onready var ground_movement: PlayerGroundMovementHandler = $MovementHandlers/GroundMovement


func _ready() -> void:
	super()
	LevelManager.current_player = self
	var meshes := %GeneralSkeleton.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		m.layers = mesh_layer
	anim_tree_state = animation_tree["parameters/LowerBody/playback"]
	animation_tree.process_mode = Node.PROCESS_MODE_INHERIT

	for attribute in find_children("", "BaseAttribute", false):
		player_attributes[attribute.attribute_name] = attribute

	health_attribute = player_attributes.get("health")
	stamina_attribute = player_attributes.get("stamina")
	visibility_attribute = player_attributes.get("visibility")

	EventBus.player_spawned.emit(self)


func _process(_delta: float) -> void:
	var move_amount := velocity.length()
	animation_tree["parameters/LowerBody/Standing/blend_position"].y = remap(-velocity.z, -10.0, 10.0, -1.0, 1.0)
	animation_tree["parameters/LowerBody/Crouching/blend_position"].y = remap(move_amount, -8.0, 8.0, -1.0, 1.0)


func _physics_process(_delta: float) -> void:
	_update_liquid_level()
	state_chart.set_expression_property("in_liquid", liquid_level >= LiquidLevel.BODY)


func _unhandled_input(event: InputEvent) -> void:
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	if event.is_action_pressed("test"):
		#set_collision_layer_value(PhysicsLayers.PLAYER, not get_collision_layer_value(PhysicsLayers.PLAYER))
		if not health_attribute.is_alive:
			LevelManager.start_new_game("res://levels/test.tscn")
		elif Input.is_action_pressed("sprint"):
			LevelManager.load_game("test")
		elif Input.is_action_pressed("crouch"):
			LevelManager.delete_save("test")
		else:
			LevelManager.save_game("test", get_viewport().get_texture().get_image())

	if toggle_crouch:
		if Input.is_action_just_pressed("crouch"):
			try_crouch = !try_crouch
	else:
		try_crouch = Input.is_action_pressed("crouch")


func increase_attribute(attribute_name: String, value: float, value_type: BaseAttribute.ValueType) -> bool:
	var attribute: BaseAttribute = player_attributes.get(attribute_name)
	if not attribute:
		print("Increase attribute: " + attribute_name + " Attribute not found")
		return false

	if value_type == BaseAttribute.ValueType.CURRENT:
		if attribute.value == attribute.max_value:
			return false
		attribute.add(value)
		return true

	if value_type == BaseAttribute.ValueType.MAX:
		attribute.max_value += value
		attribute.add(value)
		return true
	return false


func decrease_attribute(attribute_name: String, value: float) -> void:
	var attribute: BaseAttribute = player_attributes.get(attribute_name)
	if not attribute:
		print("Decrease attribute: " + attribute_name + " - Attribute not found")
		return
	attribute.subtract(value)


func jump() -> void:
	decrease_attribute("stamina", stamina_attribute.jump_exhaustion)

	velocity.y += crouch_jump_velocity if is_crouching else jump_velocity


func _on_standing_state_entered() -> void:
	is_crouching = false
	standing_collision.disabled = false
	crouching_collision.disabled = true
	anim_tree_state.travel("Standing")
	try_crouch = false


func _on_crouching_state_entered() -> void:
	is_crouching = true
	standing_collision.disabled = true
	crouching_collision.disabled = false
	anim_tree_state.travel("Crouching")


func _on_health_attribute_died() -> void:
	state_chart.send_event("died")
	anim_tree_state.travel("Death")
	wield_controller.switch_wieldable(null)


func _on_health_attribute_damage_taken(hit_info: HitInfo) -> void:
	if hit_info.direction.is_zero_approx():
		return

	var kick_scale := clampf(hit_info.actual_damage / damage_for_full_kick, 0.0, 1.0)
	camera_effects.add_damage_kick(damage_kick_pitch * kick_scale, damage_kick_roll * kick_scale, hit_info.impact_position)


func _on_standing_state_physics_processing(delta: float) -> void:
	if try_crouch and is_on_floor():
		state_chart.send_event("onCrouching")
	camera_controller.update_camera_height(delta, standing_camera_height)


func _on_crouching_state_physics_processing(delta: float) -> void:
	if _should_stand_up():
		state_chart.send_event("onStanding")
	camera_controller.update_camera_height(delta, crouch_camera_height)


func _should_stand_up() -> bool:
	if crouch_check.is_colliding():
		return false

	if is_on_floor():
		return not try_crouch
	else:
		return false


func _on_lying_dead_state_physics_processing(delta: float) -> void:
	camera_controller.update_camera_height(delta, death_camera_height)

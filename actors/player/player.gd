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
@export var slide_jump_velocity := 4.0
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

@export_group("Audio")
@export var jump_sound: AudioStream

@export_subgroup("Footstep Audio")
@export var walk_volume_db := -38.0
@export var sprint_volume_db := -30.0
@export var crouch_volume_db := -60.0

@export_subgroup ("Landing Audio")
@export var landing_threshold := -2.0
@export var max_landing_velocity := -8.0
@export var min_landing_velocity := -2.0
@export var max_volume_db := 0.0
@export var min_volume_db := -40.0
@export var max_pitch := 0.8
@export var min_pitch := 0.7

var try_crouch := false

var is_sprinting := false
var is_crouching := false
var is_sliding := false

var jumped_from_slide := false

var anim_tree_state: AnimationNodeStateMachinePlayback

var player_attributes: Dictionary[String, BaseAttribute]
var health_attribute: HealthAttribute
var stamina_attribute: StaminaAttribute
var visibility_attribute: BaseAttribute

var _can_play_footstep := true

@onready var input_controller: InputController = $InputController
@onready var ground_movement: PlayerGroundMovementHandler = $MovementHandlers/GroundMovement
@onready var ladder_movement: PlayerLadderMovementHandler = $MovementHandlers/LadderMovement
@onready var sitting_handler: PlayerSittingHandler = $MovementHandlers/SittingHandler
@onready var footstep_player: FootstepPlayer = $FootstepPlayer
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent
@onready var sliding_audio_player: AudioStreamPlayer3D = $SlidingAudioPlayer


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

	if toggle_crouch:
		if input_controller.crouch_just_pressed:
			try_crouch = not try_crouch
	else:
		try_crouch = input_controller.crouch_pressed


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		#set_collision_layer_value(PhysicsLayers.PLAYER, not get_collision_layer_value(PhysicsLayers.PLAYER))
		if not health_attribute.is_alive:
			LevelManager.start_new_game("res://levels/test.tscn")
		elif input_controller.sprint_pressed:
			if not LevelManager.get_save_slot_info("test"):
				print("Save is missing")
				return
			LevelManager.load_game("test")
		elif input_controller.crouch_pressed:
			LevelManager.delete_save("test")
		else:
			LevelManager.save_game("test", get_viewport().get_texture().get_image())


func save_state() -> Dictionary:
	var state := super()
	state[&"try_crouch"] = try_crouch
	state[&"is_sprinting"] = is_sprinting
	state[&"is_crouching"] = is_crouching
	state[&"jumped_from_slide"] = jumped_from_slide
	state[&"standing_collision_disabled"] = standing_collision.disabled
	state[&"crouching_collision_disabled"] = crouching_collision.disabled
	SaveUtils.save_state_chart(state, &"state_chart", state_chart)
	state[&"ground_movement"] = ground_movement.save_state()
	state[&"ladder_movement"] = ladder_movement.save_state()
	state[&"sitting_handler"] = sitting_handler.save_state()
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	try_crouch = state.get(&"try_crouch", false)
	is_sprinting = state.get(&"is_sprinting", false)
	is_crouching = state.get(&"is_crouching", false)
	jumped_from_slide = state.get(&"jumped_from_slide", false)
	standing_collision.disabled = state.get(&"standing_collision_disabled", false)
	crouching_collision.disabled = state.get(&"crouching_collision_disabled", true)
	SaveUtils.load_state_chart(state, &"state_chart", state_chart)
	ground_movement.load_state(state.get(&"ground_movement", Dictionary()))
	ladder_movement.load_state(state.get(&"ladder_movement", Dictionary()))
	sitting_handler.load_state(state.get(&"sitting_handler", Dictionary()))


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
	AudioManager.play_sound_3d(jump_sound, global_position)
	decrease_attribute("stamina", stamina_attribute.jump_exhaustion)

	if is_sliding:
		velocity.y += slide_jump_velocity
		jumped_from_slide = true
	else:
		velocity.y += crouch_jump_velocity if is_crouching else jump_velocity
	state_chart.set_expression_property(&"is_jumping", true)


func handle_movement_sound() -> void:
	if velocity.length() >= 0.2 and not is_sliding:
		_play_footstep_sound()


func handle_landing(current_fall_velocity: float) -> void:
	if current_fall_velocity < landing_threshold:
		var velocity_ratio := clampf((current_fall_velocity - min_landing_velocity) / (max_landing_velocity - min_landing_velocity), 0.0, 1.0)
		var volume := lerpf(min_volume_db, max_volume_db, velocity_ratio)
		var pitch := lerpf(max_pitch, min_pitch, velocity_ratio)
		footstep_player.play_landing(volume, pitch, current_fall_velocity)


func _on_standing_state_entered() -> void:
	is_crouching = false
	state_chart.set_expression_property(&"is_crouching", false)
	standing_collision.disabled = false
	crouching_collision.disabled = true
	anim_tree_state.travel("Standing")
	try_crouch = false


func _on_crouching_state_entered() -> void:
	is_crouching = true
	state_chart.set_expression_property(&"is_crouching", true)
	standing_collision.disabled = true
	crouching_collision.disabled = false
	anim_tree_state.travel("Crouching")


func _on_health_attribute_died() -> void:
	state_chart.set_expression_property(&"is_dead", true)
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

	return jumped_from_slide or (is_on_floor() and not try_crouch)


func _on_lying_dead_state_physics_processing(delta: float) -> void:
	camera_controller.update_camera_height(delta, death_camera_height)


func _play_footstep_sound() -> void:
	var step_sin := sin(camera_effects.step_timer * 6.0 * PI)
	if _can_play_footstep && step_sin > 0.9:
		var volume: float
		if is_crouching:
			volume = crouch_volume_db
		elif is_sprinting:
			volume = sprint_volume_db
		else:
			volume = walk_volume_db
		footstep_player.play_footstep(volume, velocity.length())
		_can_play_footstep = false

	if !_can_play_footstep && step_sin < 0.9:
		_can_play_footstep = true

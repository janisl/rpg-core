class_name LockpickMinigame
extends Node3D

const MIN_RANGE := 0.0
const LOCKPICK_SUCCESS_ZONE := -90.0

signal unlocked
signal cancelled
signal lockpick_broke

@export var default_sweet_spot_range: float = 10.0

@export var max_range := 10.0
@export var lockpick_move_sensitivity := 0.003

@export var lockpick_pivot: Node3D
@export var keyhole_pivot: Node3D

@export var lockpick_health_max := 5.0
@export_range(1, 10, 0.5, "Default = 2.0") var lockpick_damage_per_second_min := 2.0
@export_range(1, 10, 0.5, "Default = 8.0") var lockpick_damage_per_second_max := 8.0

@export var keyhole_rotation_speed := 4.0

@export_subgroup("Attribute Skill Settings")
@export var attribute_influences_difficulty := true
@export var attribute_influences_lockpick_health := true

@export_subgroup("Animations")
@export var start_animation := "start"
@export var grab_new_lockpick_animation := "grab_new_lockpick"
@export var jiggle_animation := "jiggle_lock"
@export var lockpick_break_animation := "lockpick_breaks"
@export var unlock_animation := "unlocking"

@export_subgroup("Audio")
@export var unlock_sound: AudioStream
@export var jiggle_sound: AudioStream
@export var lockpick_break_sound: AudioStream

var _lockpick_health: float:
	set(value):
		_lockpick_health = maxf(value, 0)

var _is_unlocked := false
var _is_turning_keyhole := false
var _is_changing_lockpicks := false
var _is_jiggling := false

var _sweet_spot_range: float
var _lockpick_spot: float
var _sweet_spot := 0.0

var _lockpick_attribute: BaseAttribute

var _unlock_difficulty_modifier := 0.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_lockpick_spot = max_range / 2
	_lockpick_health = lockpick_health_max
	_sweet_spot_range = default_sweet_spot_range

	animation_player.play(start_animation)
	await animation_player.animation_finished

	_place_sweetspot()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not _is_turning_keyhole and not _is_changing_lockpicks and not _is_unlocked:
			lockpick_pivot.rotate_z(-event.relative.x * lockpick_move_sensitivity)
			lockpick_pivot.rotation.z = clampf(lockpick_pivot.rotation.z, deg_to_rad(-90), deg_to_rad(90))

	if event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		cancelled.emit()


func _physics_process(delta: float) -> void:
	_lockpick_spot = snappedf(remap(rad_to_deg(lockpick_pivot.rotation.z), -90, 90, MIN_RANGE, max_range), 0.1)

	if not _is_unlocked:
		_handle_keyhole(delta)


func pass_player_attribute(passed_lockpick_attribute: BaseAttribute) -> void:
	_lockpick_attribute = passed_lockpick_attribute
	_set_attribute_dependencies()


func grab_new_lockpick() -> void:
	_is_changing_lockpicks = true

	if grab_new_lockpick_animation:
		animation_player.play(grab_new_lockpick_animation)
		await animation_player.animation_finished

	_lockpick_health = lockpick_health_max
	_is_changing_lockpicks = false


func exit_game() -> void:
	if start_animation:
		animation_player.play_backwards(start_animation)
		await animation_player.animation_finished

	cancelled.emit()


func _place_sweetspot() -> void:
	var rand_range: RandomNumberGenerator = RandomNumberGenerator.new()
	_sweet_spot = snappedf(rand_range.randf_range(MIN_RANGE, max_range), 0.1)


func _set_attribute_dependencies() -> void:
	var normalized_lockpick_attribute := _lockpick_attribute.value / _lockpick_attribute.max_value

	if attribute_influences_difficulty:
		_sweet_spot_range = normalized_lockpick_attribute * default_sweet_spot_range
		_unlock_difficulty_modifier = (normalized_lockpick_attribute * 10)

	if attribute_influences_lockpick_health:
		var adjusted_lockpick_health := lockpick_health_max * normalized_lockpick_attribute
		lockpick_health_max = adjusted_lockpick_health
		_lockpick_health = adjusted_lockpick_health


func _handle_keyhole(delta: float) -> void:
	if _is_jiggling or _is_changing_lockpicks:
		return

	if Input.is_action_pressed("move_right"):
		keyhole_pivot.rotate_z(-keyhole_rotation_speed * delta)
		_is_turning_keyhole = true
	else:
		keyhole_pivot.rotation.z = lerp_angle(keyhole_pivot.rotation.z, 0, 4 * delta)
		_is_turning_keyhole = false

	var distance := absf(_lockpick_spot - _sweet_spot)
	var grad_lock := snappedf(remap(distance, _sweet_spot_range, 0, 0, LOCKPICK_SUCCESS_ZONE), 0.1)
	keyhole_pivot.rotation_degrees.z = clampf(keyhole_pivot.rotation_degrees.z, grad_lock, 0)

	if rad_to_deg(keyhole_pivot.rotation.z) <= LOCKPICK_SUCCESS_ZONE + _unlock_difficulty_modifier:
		_unlock_lock()
	elif _is_turning_keyhole:
		if distance <= 1:
			if abs(grad_lock - rad_to_deg(keyhole_pivot.rotation.z)) <= 1:
				_jiggle_lock(delta, distance)
		else:
			_jiggle_lock(delta, distance)


func _jiggle_lock(delta: float, distance_to_unlock: float) -> void:
	if _is_changing_lockpicks:
		return

	_is_jiggling = true
	AudioManager.play_ui_sound(jiggle_sound)

	var lockpick_damage := remap(distance_to_unlock, 0, 10, lockpick_damage_per_second_min, lockpick_damage_per_second_max)
	_lockpick_health = _lockpick_health - (lockpick_damage * delta)

	if _lockpick_health == 0:
		_on_lockpick_break()
	else:
		animation_player.play(jiggle_animation)
		await animation_player.animation_finished

	_is_jiggling = false


func _unlock_lock() -> void:
	AudioManager.play_ui_sound(unlock_sound)

	_is_unlocked = true

	if unlock_animation:
		animation_player.play(unlock_animation)
		await animation_player.animation_finished

	unlocked.emit()


func _on_lockpick_break() -> void:
	_is_changing_lockpicks = true

	AudioManager.play_ui_sound(lockpick_break_sound)

	if lockpick_break_animation:
		animation_player.play(lockpick_break_animation)
		await animation_player.animation_finished

	lockpick_broke.emit()

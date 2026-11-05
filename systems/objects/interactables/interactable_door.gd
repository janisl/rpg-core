@tool
class_name InteractableDoor
extends DynamicObject

signal object_state_updated(interaction_text: String)
signal door_state_changed(is_open: bool)
signal lock_state_updated(lock_interaction_text: String)
signal lock_state_changed(is_locked: bool)

enum DoorType {
	ROTATING,
	SLIDING,
	ANIMATED,
}

enum ForcedRotationAxis {
	None,
	AxisX,
	AxisY,
	AxisZ,
}

@export_group("Door Settings")
@export var is_open := false
@export var auto_close_time := 0.0
@export var doors_to_sync_with: Array[NodePath]
@export var is_locked := false
@export var key: ItemData
@export var key_hint: String

@export_group("Door Parameters")
@export var door_type := DoorType.ROTATING:
	set(value):
		door_type = value
		notify_property_list_changed()

@export var door_speed := 1.0
@export var open_position := Vector3.ZERO
@export var closed_position := Vector3.ZERO
@export var open_rotation := Vector3.ZERO
@export var closed_rotation := Vector3.ZERO
@export var bidirectional_swing := false
@export var forced_rotation_axis := ForcedRotationAxis.None
@export var angle_tolerance := 1.0
@export var animation_player : NodePath
@export var opening_animation : String
@export var closing_animation : String
@export var reverse_opening_anim_for_close := true:
	set(value):
		reverse_opening_anim_for_close = value
		notify_property_list_changed()

@export_group("Interaction Settings")
@export var ignore_interaction_raycast := false
@export var interaction_text_when_closed := "INTERACT Open"
@export var interaction_text_when_open := "INTERACT Close"
@export var interaction_text_when_locked := "INTERACT Unlock"
@export var interaction_text_when_unlocked := "INTERACT Lock"

@export_group("Audio")
@export var audio_player: AudioStreamPlayer3D
@export var open_sound: AudioStream
@export var close_sound: AudioStream
@export var rattle_sound: AudioStream
@export var unlock_sound: AudioStream
@export var lock_sound: AudioStream

var _is_moving := false
var _target_rotation_vector := Vector3.ZERO
var _target_position := Vector3.ZERO
var _anim_player: AnimationPlayer
var _close_timer: Timer


func _ready() -> void:
	super()
	if !ignore_interaction_raycast:
		add_to_group("interactable")

	if !audio_player:
		var players := find_children("", "AudioStreamPlayer3D")
		if len(players):
			audio_player = players[0]

	if door_type == DoorType.ANIMATED:
		_anim_player = get_node(animation_player)

	object_state_updated.emit(interaction_text_when_open if is_open else interaction_text_when_closed)
	lock_state_updated.emit(interaction_text_when_locked if is_locked else interaction_text_when_unlocked)


func _validate_property(property: Dictionary) -> void:
	if property.name in [
			"open_rotation",
			"closed_rotation",
			"bidirectional_swing",
			"forced_rotation_axis",
			"angle_tolerance"] and door_type != DoorType.ROTATING:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in [
			"open_position",
			"closed_position"] and door_type != DoorType.SLIDING:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in [
			"animation_player",
			"opening_animation",
			"reverse_opening_anim_for_close",
			"closing_animation"] and door_type != DoorType.ANIMATED:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in ["closing_animation"] and reverse_opening_anim_for_close:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func _physics_process(delta: float) -> void:
	if door_type == DoorType.ROTATING and _is_moving:
		_update_rotating(delta)
	elif door_type == DoorType.SLIDING and _is_moving:
		_update_sliding(delta)


func save_state() -> Dictionary:
	var state := super()
	state[&"is_open"] = is_open
	state[&"is_locked"] = is_locked
	state[&"is_moving"] = _is_moving
	state[&"target_rotation_vector"] = _target_rotation_vector
	state[&"target_position"] = _target_position
	if _close_timer and !_close_timer.is_queued_for_deletion():
		state[&"close_time_left"] = _close_timer.time_left
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	is_open = state.get(&"is_open", false)
	is_locked = state.get(&"is_locked", false)
	_is_moving = state.get(&"is_moving", false)
	_target_rotation_vector = state.get(&"target_rotation_vector", _target_rotation_vector)
	_target_position = state.get(&"target_position", _target_position)

	if door_type == DoorType.ANIMATED:
		_snap_animation()

	if _close_timer:
		_close_timer.queue_free()
		_close_timer = null
	var close_time_left: float = state.get(&"close_time_left", 0.0)
	if is_open and close_time_left > 0:
		_start_close_timer(close_time_left)


func interact(player: Player) -> void:
	if is_locked:
		_door_rattle()
	elif !is_open:
		open_door(player)

		for nodepath in doors_to_sync_with:
			if nodepath:
				var object := get_node(nodepath)
				object.open_door(player)
	else:
		close_door()

		for nodepath in doors_to_sync_with:
			if nodepath:
				var object := get_node(nodepath)
				object.close_door()


func open_door(player: Player) -> void:
	_play_sound(open_sound)

	if door_type == DoorType.ANIMATED:
		_anim_player.play(opening_animation)
	elif door_type == DoorType.ROTATING:
		_target_rotation_vector = open_rotation
		var swing_direction := 1

		if bidirectional_swing:
			var offset := player.global_position - global_position
			var offset_dot_product := offset.dot(global_transform.basis.z)
			swing_direction = -1 if offset_dot_product < 0 else 1

		_target_rotation_vector = open_rotation * swing_direction
		_is_moving = true
	else:
		_target_position = open_position
		_is_moving = true

	is_open = true
	object_state_updated.emit(interaction_text_when_open)
	door_state_changed.emit(true)

	if auto_close_time > 0:
		_start_close_timer(auto_close_time)


func close_door() -> void:
	if _close_timer:
		_close_timer.queue_free()

	_play_sound(close_sound)

	if door_type == DoorType.ANIMATED:
		if reverse_opening_anim_for_close:
			_anim_player.play_backwards(opening_animation)
		else:
			_anim_player.play(closing_animation)
	elif door_type == DoorType.ROTATING:
		_target_rotation_vector = closed_rotation
		_is_moving = true
	else:
		_target_position = closed_position
		_is_moving = true

	is_open = false
	object_state_updated.emit(interaction_text_when_closed)
	door_state_changed.emit(false)


func unlock_door() -> void:
	_play_sound(unlock_sound)

	is_locked = false
	lock_state_changed.emit(is_locked)
	lock_state_updated.emit(interaction_text_when_unlocked)


func lock_door() -> void:
	_play_sound(lock_sound)

	is_locked = true
	lock_state_changed.emit(is_locked)
	lock_state_updated.emit(interaction_text_when_locked)


func lock_unlock_switch() -> void:
	if is_locked:
		unlock_door()
	else:
		lock_door()

	for nodepath in doors_to_sync_with:
		if nodepath != null:
			var object := get_node(nodepath)
			object.lock_unlock_switch()


func _update_rotating(delta: float) -> void:
	match forced_rotation_axis:
		ForcedRotationAxis.None:
			rotation = rotation.move_toward(_target_rotation_vector, delta * door_speed)
			if _vectors_approx_equal(_target_rotation_vector, rotation_degrees, angle_tolerance):
				_is_moving = false

		ForcedRotationAxis.AxisX:
			rotation.x = lerp_angle(deg_to_rad(rotation_degrees.x), deg_to_rad(_target_rotation_vector.x), clampf(delta * door_speed, 0.0, 1.0))
			if rotation_degrees.x == _target_rotation_vector.x:
				_is_moving = false

		ForcedRotationAxis.AxisY:
			rotation.y = lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(_target_rotation_vector.y), clampf(delta * door_speed, 0.0, 1.0))
			if rotation_degrees.y == _target_rotation_vector.y:
				_is_moving = false

		ForcedRotationAxis.AxisZ:
			rotation.x = lerp_angle(deg_to_rad(rotation_degrees.z), deg_to_rad(_target_rotation_vector.z), clampf(delta * door_speed, 0.0, 1.0))
			if rotation_degrees.z == _target_rotation_vector.z:
				_is_moving = false


func _update_sliding(delta: float) -> void:
	position = position.move_toward(_target_position, door_speed * delta)
	if position.is_equal_approx(_target_position):
		_is_moving = false


func _vectors_approx_equal(v1 : Vector3, v2 : Vector3, epsilon : float) -> bool:
	var diff := v1 - v2
	return abs(diff.x) < epsilon and abs(diff.y) < epsilon and abs(diff.z) < epsilon


func _door_rattle() -> void:
	_play_sound(rattle_sound)
	EventBus.show_notification.emit(tr("DOOR HINT Locked"))


func _play_sound(sound: AudioStream) -> void:
	if audio_player and sound:
		audio_player.stream = sound
		audio_player.play()


func _start_close_timer(time: float) -> void:
	_close_timer = Timer.new()
	add_child(_close_timer)
	_close_timer.wait_time = time
	_close_timer.one_shot = true
	_close_timer.start()
	_close_timer.timeout.connect(_on_auto_close_time)


func _snap_animation() -> void:
	if is_open:
		_anim_player.play(opening_animation)
		_anim_player.seek(_anim_player.current_animation_length, true)
	elif reverse_opening_anim_for_close:
		_anim_player.play(opening_animation)
		_anim_player.seek(0.0, true)
		_anim_player.stop(true)
	else:
		_anim_player.play(closing_animation)
		_anim_player.seek(_anim_player.current_animation_length, true)


func _on_auto_close_time() -> void:
	close_door()

@tool
class_name InteractableDoor
extends DynamicObject

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
@export var ignore_interaction_raycast := false

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

var _is_moving := false
var _target_rotation_vector := Vector3.ZERO
var _anim_player: AnimationPlayer


func _ready() -> void:
	super()
	if !ignore_interaction_raycast:
		add_to_group("interactable")

	if door_type == DoorType.ANIMATED:
		_anim_player = get_node(animation_player)


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


func interact(player: Player) -> void:
	if !is_open:
		open_door(player)
	else:
		close_door()


func open_door(player: Player) -> void:
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
		var tween_door := get_tree().create_tween()
		tween_door.tween_property(self, "position", open_position, door_speed)

	is_open = true


func close_door() -> void:
	if door_type == DoorType.ANIMATED:
		if reverse_opening_anim_for_close:
			_anim_player.play_backwards(opening_animation)
		else:
			_anim_player.play(closing_animation)
	elif door_type == DoorType.ROTATING:
		_target_rotation_vector = closed_rotation
		_is_moving = true
	else:
		var tween_door := get_tree().create_tween()
		tween_door.tween_property(self, "position", closed_position, door_speed)

	is_open = false


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


func _vectors_approx_equal(v1 : Vector3, v2 : Vector3, epsilon : float) -> bool:
	var diff := v1 - v2
	return abs(diff.x) < epsilon and abs(diff.y) < epsilon and abs(diff.z) < epsilon

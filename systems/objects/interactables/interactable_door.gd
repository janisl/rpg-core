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

@export var open_position := Vector3.ZERO
@export var closed_position := Vector3.ZERO
@export var open_rotation := Vector3.ZERO
@export var closed_rotation := Vector3.ZERO
@export var bidirectional_swing := false
@export var forced_rotation_axis := ForcedRotationAxis.None
@export var angle_tolerance := 1.0
@export var door_speed := 1.0

var is_moving := false
var target_rotation_vector := Vector3.ZERO


func _ready() -> void:
	super()
	if !ignore_interaction_raycast:
		add_to_group("interactable")


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
	pass


func _physics_process(delta: float) -> void:
	if door_type == DoorType.ROTATING and is_moving:
		_update_rotating(delta)


func interact(player: Player) -> void:
	if !is_open:
		open_door(player)
	else:
		close_door()


func open_door(player: Player) -> void:
	if door_type == DoorType.ROTATING:
		target_rotation_vector = open_rotation
		var swing_direction := 1

		if bidirectional_swing:
			var offset := player.global_position - global_position
			var offset_dot_product := offset.dot(global_transform.basis.z)
			swing_direction = -1 if offset_dot_product < 0 else 1

		target_rotation_vector = open_rotation * swing_direction
		is_moving = true
	else:
		var tween_door := get_tree().create_tween()
		tween_door.tween_property(self, "position", open_position, door_speed)

	is_open = true


func close_door() -> void:
	if door_type == DoorType.ROTATING:
		target_rotation_vector = closed_rotation
		is_moving = true
	else:
		var tween_door := get_tree().create_tween()
		tween_door.tween_property(self, "position", closed_position, door_speed)

	is_open = false


func _update_rotating(delta: float) -> void:
	match forced_rotation_axis:
		ForcedRotationAxis.None:
			rotation = rotation.move_toward(target_rotation_vector, delta * door_speed)
			if _vectors_approx_equal(target_rotation_vector, rotation_degrees, angle_tolerance):
				is_moving = false

		ForcedRotationAxis.AxisX:
			rotation.x = lerp_angle(deg_to_rad(rotation_degrees.x), deg_to_rad(target_rotation_vector.x), clampf(delta * door_speed, 0.0, 1.0))
			if rotation_degrees.x == target_rotation_vector.x:
				is_moving = false

		ForcedRotationAxis.AxisY:
			rotation.y = lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(target_rotation_vector.y), clampf(delta * door_speed, 0.0, 1.0))
			if rotation_degrees.y == target_rotation_vector.y:
				is_moving = false

		ForcedRotationAxis.AxisZ:
			rotation.x = lerp_angle(deg_to_rad(rotation_degrees.z), deg_to_rad(target_rotation_vector.z), clampf(delta * door_speed, 0.0, 1.0))
			if rotation_degrees.z == target_rotation_vector.z:
				is_moving = false


func _vectors_approx_equal(v1 : Vector3, v2 : Vector3, epsilon : float) -> bool:
	var diff := v1 - v2
	return abs(diff.x) < epsilon and abs(diff.y) < epsilon and abs(diff.z) < epsilon

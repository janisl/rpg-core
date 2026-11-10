@tool
class_name DynamicObject
extends Node3D

@export var display_name: String

@export_group("Object Size and Shape")
@export var custom_aabb := AABB()


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	add_to_group("persist")


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"position"] = position
	state[&"rotation"] = rotation
	var rigid_body := self as Node3D as RigidBody3D
	if rigid_body:
		state[&"linear_velocity"] = rigid_body.linear_velocity
		state[&"angular_velocity"] = rigid_body.angular_velocity
	state[&"display_name"] = display_name
	return state


func load_state(state: Dictionary) -> void:
	position = state.get(&"position", position)
	rotation = state.get(&"rotation", rotation)
	var rigid_body := self as Node3D as RigidBody3D
	if rigid_body:
		rigid_body.linear_velocity = state.get(&"linear_velocity", Vector3.ZERO)
		rigid_body.angular_velocity = state.get(&"angular_velocity", Vector3.ZERO)
	display_name = state.get(&"display_name", "")


func get_aabb() -> AABB:
	if custom_aabb:
		return custom_aabb

	var aabb : AABB = AABB()
	for child in find_children("*", "MeshInstance3D", true, false):
		if child.visible:
			aabb = aabb.merge(child.transform * child.get_aabb())

	return aabb

@tool
class_name DynamicObject
extends Node3D

@export var display_name: String


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
	return state


func load_state(state: Dictionary) -> void:
	position = state.get(&"position", position)
	rotation = state.get(&"rotation", rotation)
	var rigid_body := self as Node3D as RigidBody3D
	if rigid_body:
		rigid_body.linear_velocity = state.get(&"linear_velocity", Vector3.ZERO)
		rigid_body.angular_velocity = state.get(&"angular_velocity", Vector3.ZERO)

class_name DynamicObject
extends Node3D


func _ready() -> void:
	add_to_group("persist")


func save_state() -> Dictionary:
	var state := Dictionary()
	state.position = position
	state.rotation = rotation
	var rigid_body := self as Node3D as RigidBody3D
	if rigid_body:
		state.linear_velocity = rigid_body.linear_velocity
		state.angular_velocity = rigid_body.angular_velocity
	return state


func load_state(state: Dictionary) -> void:
	position = state.position
	rotation = state.rotation
	var rigid_body := self as Node3D as RigidBody3D
	if rigid_body:
		rigid_body.linear_velocity = state.linear_velocity
		rigid_body.angular_velocity = state.angular_velocity

class_name DynamicObject
extends RigidBody3D


func _ready() -> void:
	add_to_group("persist")


func save_state() -> Dictionary:
	var state := Dictionary()
	state.position = position
	state.rotation = rotation
	state.linear_velocity = linear_velocity
	state.angular_velocity = angular_velocity
	return state


func load_state(state: Dictionary) -> void:
	position = state.position
	rotation = state.rotation
	linear_velocity = state.linear_velocity
	angular_velocity = state.angular_velocity

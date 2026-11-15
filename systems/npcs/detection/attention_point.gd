class_name AttentionPoint
extends Node3D

@onready var sprite: Sprite3D = $Sprite

var is_active: bool:
	set(value):
		is_active = value
		visible = is_active and DevTools.show_attention_points


func _init() -> void:
	visible = false


func save_state() -> Dictionary:
	var state := Dictionary()
	state[&"position"] = position
	state[&"is_active"] = is_active
	return state


func load_state(state: Dictionary) -> void:
	position = state.get(&"position", position)
	is_active = state.get(&"is_active", false)

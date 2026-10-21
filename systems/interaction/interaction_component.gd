class_name InteractionComponent
extends Node3D

signal was_interacted_with()

@export var input_map_action := "interact"
@export var interaction_text : String
@export var is_disabled := false


@warning_ignore("unused_parameter")
func interact(player: Player):
	pass


func _emit_was_interacted_with() -> void:
	was_interacted_with.emit()

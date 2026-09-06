class_name PlayerStateMachine
extends Node

@export_group("Refernces")
@export var player: Player


func _process(_delta: float) -> void:
	if player:
		player.state_chart.set_expression_property("Looking at: ", player.interaction_ray_cast.current_object)

class_name Level
extends Node3D

@export var connectors: Array[Node3D]


func move_player_to_connector(player: Player, connector_name: String) -> void:
	for node in connectors:
		if node.get_name() == connector_name:
			player.global_position = node.global_position
			player.global_rotation = node.global_rotation
			player.velocity = Vector3.ZERO
			return

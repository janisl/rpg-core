class_name PlayerStateBehaviour
extends StateBehaviour

var player: Player


func _ready() -> void:
	super()

	player = _find_owner() as Player

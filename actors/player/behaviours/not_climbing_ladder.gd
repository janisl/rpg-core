extends PlayerStateBehaviour

signal check_for_ladder


func _on_state_physics_processing(_delta: float) -> void:
	check_for_ladder.emit()

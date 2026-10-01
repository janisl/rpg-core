extends PlayerStateBehaviour

signal check_for_swim


func _on_state_physics_processing(delta: float) -> void:
	check_for_swim.emit()

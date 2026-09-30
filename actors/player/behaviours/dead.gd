extends PlayerStateBehaviour


func _on_state_entered() -> void:
	player.anim_tree_state.travel("Death")


func _on_state_processing(delta: float) -> void:
	player.camera_controller.update_camera_height(delta, player.death_camera_height)
